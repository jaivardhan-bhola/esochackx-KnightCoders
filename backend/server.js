const express = require('express');
const axios = require('axios');

const app = express();
app.use(express.json());

app.post('/process-complaint', async (req, res) => {
    const { complaint, location, imagePath } = req.body;

    try {
        const response = await axios.post('http://localhost:5000/process_complaint', {
            complaint,
            location,
            image_path: imagePath
        });

        res.json(response.data);
    } catch (error) {
        console.error(error);
        res.status(500).send('Error processing complaint');
    }
});

app.post('/analyze-post', async (req, res) => {
    const { postText, imagePaths } = req.body;

    try {
        const response = await axios.post('http://localhost:5000/analyze_post', {
            post_text: postText,
            image_paths: imagePaths
        });

        res.json(response.data);
    } catch (error) {
        console.error(error);
        res.status(500).send('Error analyzing post');
    }
});

app.get('/health', async (req, res) => {
    try {
        const response = await axios.get('http://localhost:5000/health');
        res.json(response.data);
    } catch (error) {
        console.error('Flask API health check failed:', error.message);
        res.status(503).json({
            status: 'error',
            message: 'ML service unavailable',
            error: error.message
        });
    }
});

app.listen(3000, () => {
    console.log('Node.js server running on port 3000');
});