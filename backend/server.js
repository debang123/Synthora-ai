const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const http = require('http');
const WebSocket = require('ws');

let createClient;
try {
    const supabaseJs = require('@supabase/supabase-js');
    createClient = supabaseJs.createClient;
} catch (e) {
    console.warn('Supabase JS module not found, using local mock.');
    createClient = require('./supabase-mock').createClient;
}

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const PORT = 5001;
const FASTAPI_URL = 'http://127.0.0.1:8001';
const FASTAPI_WS_URL = 'ws://127.0.0.1:8001/ws/enhance';

// Supabase Configuration (Placeholder)
const SUPABASE_URL = 'https://bddtrsuxwddyybbajwxb.supabase.co';
const SUPABASE_KEY = 'sb_publishable_cgIh8ZbimpUOE_fDRIWCow_uMVnAscV'; 
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// Middleware
app.use(cors());
app.use(express.json());

// Ensure directories exist
const uploadDir = path.join(__dirname, '../uploads/');
const resultsDir = path.join(__dirname, '../results/');
[uploadDir, resultsDir].forEach(dir => {
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
});

// File upload configuration
const upload = multer({ dest: uploadDir });

// --- AUTH ENDPOINTS ---

app.post('/auth/signup', async (req, res) => {
    const { email, password } = req.body;
    const { data, error } = await supabase.auth.signUp({ email, password });
    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true, user: data.user });
});

app.post('/auth/login', async (req, res) => {
    const { email, password } = req.body;
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true, user: data.user, session: data.session });
});

app.post('/auth/logout', async (req, res) => {
    const { error } = await supabase.auth.signOut();
    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true });
});

// Auth Middleware
const authenticateUser = async (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token || token === 'dummy-token') {
        // Allow dummy-token for local testing if needed
        req.user = { id: 'dummy-id', email: 'guest@example.com' };
        return next();
    }

    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) return res.status(401).json({ error: 'Invalid token' });

    req.user = user;
    next();
};

app.get('/user-history', authenticateUser, async (req, res) => {
    const { data, error } = await supabase
        .from('enhanced_images')
        .select('*')
        .eq('user_id', req.user.id)
        .order('created_at', { ascending: false });

    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true, history: data || [] });
});

app.get('/user-credits', authenticateUser, (req, res) => {
    res.json({ success: true, credits: 1250 });
});

app.post('/verify-payment', authenticateUser, (req, res) => {
    res.json({ success: true, new_balance: 1350 });
});

// API Route for uploading images and processing
app.post('/upload-images', authenticateUser, upload.array('images', 10), async (req, res) => {
    try {
        if (!req.files || req.files.length === 0) {
            return res.status(400).json({ error: 'No images uploaded' });
        }

        const results = [];
        const fidelityWeight = req.body.fidelity_weight || '0.5';

        for (const file of req.files) {
            const formData = new FormData();
            formData.append('file', fs.createReadStream(file.path));
            formData.append('fidelity_weight', fidelityWeight);

            try {
                const response = await axios.post(`${FASTAPI_URL}/enhance`, formData, {
                    headers: { ...formData.getHeaders() },
                    responseType: 'arraybuffer'
                });

                const safeName = path.parse(file.originalname).name.replace(/[^a-zA-Z0-9]/g, '_');
                const resultFilename = `enhanced_${Date.now()}_${safeName}.jpg`;
                const resultPath = path.join(resultsDir, resultFilename);
                fs.writeFileSync(resultPath, response.data);

                const enhanced_url = `/results/${resultFilename}`;

                await supabase
                    .from('enhanced_images')
                    .insert([{
                        user_id: req.user.id,
                        original_name: file.originalname,
                        enhanced_url: enhanced_url
                    }]);

                results.push({
                    original: file.originalname,
                    enhanced_url: enhanced_url,
                    success: true
                });
            } catch (fastApiError) {
                console.error('Error contacting FastAPI:', fastApiError.message);
                results.push({
                    original: file.originalname,
                    error: 'Enhancement failed'
                });
            }
        }

        // Match Flutter's expected response format if possible
        res.json({ 
            success: true, 
            results,
            // Flutter ClarityApiService expects:
            enhanced_url: results.length > 0 ? results[0].enhanced_url : null,
            extracted_features: ["face_restoration", "denoising"],
            overall_score: 0.95
        });
    } catch (error) {
        console.error('Server error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.use('/results', express.static(resultsDir));

// WebSocket Relay
wss.on('connection', (clientWs) => {
    console.log('Client connected to Node.js WebSocket');
    let fastApiReady = false;
    let messageQueue = [];

    let fastApiWs;
    try {
        fastApiWs = new WebSocket(FASTAPI_WS_URL);
    } catch (err) {
        console.error('Failed to create FastAPI WebSocket:', err.message);
        clientWs.send(JSON.stringify({ error: 'AI service unavailable' }));
        clientWs.close();
        return;
    }

    fastApiWs.on('open', () => {
        fastApiReady = true;
        while (messageQueue.length > 0) {
            fastApiWs.send(messageQueue.shift());
        }
    });

    fastApiWs.on('message', (message) => {
        if (clientWs.readyState === WebSocket.OPEN) {
            clientWs.send(message.toString());
        }
    });

    clientWs.on('message', (message) => {
        if (fastApiReady && fastApiWs.readyState === WebSocket.OPEN) {
            fastApiWs.send(message.toString());
        } else if (!fastApiReady) {
            messageQueue = [message.toString()];
        }
    });

    clientWs.on('close', () => {
        if (fastApiWs && fastApiWs.readyState === WebSocket.OPEN) fastApiWs.close();
    });

    fastApiWs.on('error', (err) => {
        if (clientWs.readyState === WebSocket.OPEN) {
            clientWs.send(JSON.stringify({ error: 'AI service connection failed.' }));
        }
    });
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Node.js backend running on http://0.0.0.0:${PORT}`);
});
