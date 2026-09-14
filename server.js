/**
 * Desktop Browser Server
 * Node.js/Express server that proxies requests with desktop user-agent
 */

const express = require('express');
const axios = require('axios');
const url = require('url');
const path = require('path');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet({
    contentSecurityPolicy: false,
    frameguard: false
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP, please try again later.'
});

app.use(limiter);

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// ===== DESKTOP USER-AGENT =====
const DESKTOP_USER_AGENTS = [
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36'
];

function getRandomDesktopUA() {
    return DESKTOP_USER_AGENTS[Math.floor(Math.random() * DESKTOP_USER_AGENTS.length)];
}

// ===== VALIDATION =====

function isValidURL(urlString) {
    try {
        const parsed = new URL(urlString);
        // Only allow http and https
        if (!['http:', 'https:'].includes(parsed.protocol)) {
            return false;
        }
        return true;
    } catch (e) {
        return false;
    }
}

function isBlockedDomain(urlString) {
    try {
        const parsed = new URL(urlString);
        const hostname = parsed.hostname;
        
        // Block local network addresses
        const blockedPatterns = [
            /^localhost$/,
            /^127\./,
            /^192\.168\./,
            /^10\./,
            /^172\.(1[6-9]|2[0-9]|3[01])\./,
            /^::1$/, // IPv6 loopback
            /^fc00:/,  // IPv6 private
            /^fd00:/,  // IPv6 private
        ];

        for (let pattern of blockedPatterns) {
            if (pattern.test(hostname)) {
                return true;
            }
        }

        return false;
    } catch (e) {
        return false;
    }
}

// ===== PROXY ENDPOINT =====

/**
 * Proxy endpoint that fetches URLs with desktop user-agent
 * GET /api/proxy?url=https://example.com
 */
app.get('/api/proxy', async (req, res) => {
    try {
        const targetURL = req.query.url;

        // Validate URL parameter
        if (!targetURL) {
            return res.status(400).json({
                error: 'Missing URL parameter'
            });
        }

        // Validate URL format
        if (!isValidURL(targetURL)) {
            return res.status(400).json({
                error: 'Invalid URL format'
            });
        }

        // Block local network access
        if (isBlockedDomain(targetURL)) {
            return res.status(403).json({
                error: 'Access to this domain is not allowed'
            });
        }

        // Fetch the URL with desktop user-agent
        const response = await axios.get(targetURL, {
            headers: {
                'User-Agent': getRandomDesktopUA(),
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                'Accept-Language': 'en-US,en;q=0.5',
                'Accept-Encoding': 'gzip, deflate',
                'DNT': '1',
                'Connection': 'keep-alive',
                'Upgrade-Insecure-Requests': '1',
                'Sec-Fetch-Dest': 'document',
                'Sec-Fetch-Mode': 'navigate',
                'Sec-Fetch-Site': 'none',
                'Sec-Fetch-User': '?1',
                'Referer': targetURL
            },
            timeout: 30000,
            maxRedirects: 5,
            validateStatus: () => true // Accept all status codes
        });

        // Process the HTML to make links and forms work
        let html = response.data;

        // If it's HTML content
        if (typeof html === 'string' && response.headers['content-type']?.includes('text/html')) {
            // Wrap in desktop viewport meta tag
            html = html.replace(
                /<meta\s+name="viewport"/gi,
                '<meta name="viewport" content="width=1024, user-scalable=yes"'
            );

            // Add viewport if missing
            if (!html.includes('viewport')) {
                html = html.replace(
                    /<head[^>]*>/i,
                    '<head><meta name="viewport" content="width=1024, user-scalable=yes">'
                );
            }

            // Inject desktop mode CSS
            const desktopCSS = `
                <style>
                    html { 
                        zoom: 0.8; 
                        -webkit-user-select: text;
                        user-select: text;
                    }
                    body {
                        width: 100%;
                        max-width: 100%;
                        overflow-x: auto;
                    }
                    @media (max-width: 768px) {
                        html { zoom: 0.6; }
                    }
                </style>
            `;

            html = html.replace(/<head[^>]*>/i, (match) => {
                return match + desktopCSS;
            });

            // Make external links open in new window when in iframe
            html = html.replace(
                /<a\s+([^>]*?)href=["']([^"']+)["']/gi,
                (match, attrs, href) => {
                    // Skip fragment-only links and javascript
                    if (href.startsWith('#') || href.toLowerCase().startsWith('javascript:')) {
                        return match;
                    }
                    // Add target="_blank" if not present
                    if (!attrs.includes('target')) {
                        return `<a ${attrs}href="${href}" target="_blank"`;
                    }
                    return match;
                }
            );
        }

        // Set appropriate headers
        res.set({
            'Content-Type': response.headers['content-type'] || 'text/html; charset=utf-8',
            'X-Desktop-Mode': 'true',
            'Cache-Control': 'public, max-age=300'
        });

        // Don't set these headers
        res.removeHeader('X-Frame-Options');
        res.removeHeader('Frame-Options');

        res.send(html);

    } catch (error) {
        console.error('Proxy error:', error.message);

        // Return error response
        res.status(error.response?.status || 500).json({
            error: 'Failed to load website',
            message: error.message,
            type: error.code || 'unknown_error'
        });
    }
});

// ===== HTML PROXY ENDPOINT (for iframe) =====

/**
 * Alternative proxy that returns HTML wrapper
 * This is used when loading into iframe
 */
app.get('/api/browse', async (req, res) => {
    try {
        const targetURL = req.query.url;

        if (!targetURL || !isValidURL(targetURL) || isBlockedDomain(targetURL)) {
            return res.send(`
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=1024">
                </head>
                <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; padding: 20px; color: #333;">
                    <h2>Invalid URL</h2>
                    <p>The URL provided is invalid or access is not allowed.</p>
                </body>
                </html>
            `);
        }

        // Fetch with desktop user-agent
        const response = await axios.get(targetURL, {
            headers: {
                'User-Agent': getRandomDesktopUA(),
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                'Accept-Language': 'en-US,en;q=0.5',
                'Accept-Encoding': 'gzip, deflate'
            },
            timeout: 30000,
            maxRedirects: 5,
            validateStatus: () => true
        });

        // For HTML content, ensure desktop viewport
        if (typeof response.data === 'string' && response.headers['content-type']?.includes('text/html')) {
            let html = response.data;

            // Ensure desktop viewport
            if (html.includes('<meta name="viewport')) {
                html = html.replace(
                    /<meta\s+name="viewport"[^>]*>/i,
                    '<meta name="viewport" content="width=1024">'
                );
            } else if (html.includes('<head')) {
                html = html.replace(
                    /<head>/i,
                    '<head><meta name="viewport" content="width=1024">'
                );
            }

            res.type('text/html').send(html);
        } else {
            // For non-HTML content, pass through
            res.type(response.headers['content-type']).send(response.data);
        }

    } catch (error) {
        console.error('Browse error:', error.message);
        res.status(500).send(`
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=1024">
            </head>
            <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; padding: 40px; text-align: center; color: #666;">
                <h2>Error Loading Website</h2>
                <p>${error.message}</p>
                <p style="font-size: 12px; color: #999; margin-top: 20px;">Error: ${error.code || 'unknown_error'}</p>
            </body>
            </html>
        `);
    }
});

// ===== UTILITY ENDPOINTS =====

/**
 * Health check endpoint
 */
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

/**
 * Serve index.html for root path
 */
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

/**
 * 404 handler
 */
app.use((req, res) => {
    res.status(404).sendFile(path.join(__dirname, 'public', 'index.html'));
});

/**
 * Error handler
 */
app.use((err, req, res, next) => {
    console.error('Server error:', err);
    res.status(500).json({
        error: 'Internal server error',
        message: process.env.NODE_ENV === 'production' ? 'An error occurred' : err.message
    });
});

// ===== VERCEL ENTRY POINT =====
// Vercel invokes the exported Express app as a serverless function.
// Do not call app.listen() here.

module.exports = app;
