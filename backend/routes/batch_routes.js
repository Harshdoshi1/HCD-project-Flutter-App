const express = require("express");
const router = express.Router();
const {
    addBatch,
    getAllBatches,
    getBatchIdByName,
    getCurrentSemester
} = require("../controller/batchController");


router.post('/addBatch', addBatch);
router.get('/getAllBatches', getAllBatches);
router.get('/getBatchIdByName/:batchName', getBatchIdByName);
router.get("/getCurrentSemester/:batchId", getCurrentSemester);
module.exports = router;
