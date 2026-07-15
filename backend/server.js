const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");
const multer = require("multer");
const bodyParser = require("body-parser");

const app = express();
app.use(cors());
app.use(express.static(__dirname)); // serves admin.html
app.use(bodyParser.json());

// ================= MySQL Connection =================
const db = mysql.createConnection({
  host: "127.0.0.1",
  port: 3306,
  user: "root",
  password: "",
  database: "users_data",
}).promise();

// Test the connection
(async () => {
    try {
        await db.query('SELECT 1');
        console.log("✅ Connected to MySQL");
    } catch (err) {
        console.error("❌ Error connecting to MySQL:", err);
        process.exit(1);
    }
})();

// ================= Multer Setup =================
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});


const ALLOWED_FILE_FIELDS = [
  "profilePic",
  "cnicFront",
  "cnicBack",
  "workCert",
  "license",
  "licenseBack",
];


// ================== CUSTOMER ROUTES ==================

// 1. Customer Registration
app.post(
  "/api/customer",
  upload.fields([
    { name: "cnicFront", maxCount: 1 },
    { name: "cnicBack", maxCount: 1 },
    { name: "profilePic", maxCount: 1 },
  ]),
  async (req, res) => {
    try {
      const { fullName, cnic, phone, city } = req.body;
      const files = req.files || {};
      const sql = `INSERT INTO customers (fullName, cnic, phone, city, cnicFront, cnicBack, profilePic)
                   VALUES (?, ?, ?, ?, ?, ?, ?)`;
      const values = [
        fullName,
        cnic,
        phone,
        city,
        files.cnicFront?.[0]?.buffer || null,
        files.cnicBack?.[0]?.buffer || null,
        files.profilePic?.[0]?.buffer || null,
      ];

      const [result] = await db.query(sql, values);
      res.status(201).json({ customerId: result.insertId });
    } catch (err) {
      console.error("❌ Insert customer error:", err);
      res.status(500).json({ error: "Failed to save customer data" });
    }
  }
);

// 2. Get Customer by ID
app.get("/api/customer/:id", async (req, res) => {
  try {
    const [rows] = await db.query("SELECT * FROM customers WHERE id = ?", [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ error: "Customer not found" });

    const customer = rows[0];
    const toBase64 = (buffer) => (buffer ? buffer.toString("base64") : null);

    res.json({
      ...customer,
      cnicFront: toBase64(customer.cnicFront),
      cnicBack: toBase64(customer.cnicBack),
      profilePic: toBase64(customer.profilePic),
    });
  } catch (err) {
    console.error("❌ Error fetching customer:", err);
    res.status(500).json({ error: "Server error" });
  }
});

// 3. Update Customer Document
app.put(
  "/api/customer/:id/documents",
  upload.single("file"), // Expects a single file with field name 'file'
  async (req, res) => {
    const { id } = req.params;
    const { field } = req.query;
    const file = req.file;

    if (!field || !ALLOWED_FILE_FIELDS.includes(field)) {
      return res.status(400).json({ error: `Invalid 'field' query.` });
    }
    if (!file) {
      return res.status(400).json({ error: "No file uploaded (use form field 'file')" });
    }

    try {
      const sql = `UPDATE customers SET ${field} = ? WHERE id = ?`;
      const [result] = await db.query(sql, [file.buffer, id]);
      if (result.affectedRows === 0) return res.status(404).json({ error: "Customer not found" });
      res.json({ message: "Customer document updated successfully" });
    } catch (err) {
      console.error("❌ Error updating customer document:", err);
      res.status(500).json({ error: "Server error while updating document" });
    }
  }
);

// 4. Delete Customer Document
app.delete("/api/customer/:id/documents", async (req, res) => {
  const { id } = req.params;
  const { field } = req.query;

  if (!field || !ALLOWED_FILE_FIELDS.includes(field)) {
    return res.status(400).json({ error: `Invalid or missing 'field' query.` });
  }

  try {
    const sql = `UPDATE customers SET ${field} = NULL WHERE id = ?`;
    const [result] = await db.query(sql, [id]);
    if (result.affectedRows === 0) return res.status(404).json({ error: "Customer not found" });
    res.json({ message: "Customer document deleted successfully" });
  } catch (err) {
    console.error("❌ Error deleting customer document:", err);
    res.status(500).json({ error: "Server error" });
  }
});


// ================== WORKER ROUTES ==================

// 1. Worker Registration
app.post(
  "/api/worker",
  upload.fields([
    { name: "cnicFront", maxCount: 1 },
    { name: "cnicBack", maxCount: 1 },
    { name: "profilePic", maxCount: 1 },
    { name: "workCert", maxCount: 1 },
    { name: "license", maxCount: 1 },
    { name: "licenseBack", maxCount: 1 },
  ]),
  async (req, res) => {
    try {
      const { fullName, cnic, phone, city, skill, availableHours, about } = req.body;
      const files = req.files || {};
      const sql = `INSERT INTO workers (fullName, cnic, phone, city, skill, availableHours, about, cnicFront, cnicBack, profilePic, workCert, license, licenseBack, worker_form_completed)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;
      const values = [
        fullName, cnic, phone, city, skill, availableHours, about || null,
        files.cnicFront?.[0]?.buffer || null,
        files.cnicBack?.[0]?.buffer || null,
        files.profilePic?.[0]?.buffer || null,
        files.workCert?.[0]?.buffer || null,
        files.license?.[0]?.buffer || null,
        files.licenseBack?.[0]?.buffer || null,
        true,
      ];
      const [result] = await db.query(sql, values);
      res.json({ workerId: result.insertId });
    } catch (err) {
      console.error("❌ Worker insert error:", err);
      res.status(500).json({ error: "Failed to save worker" });
    }
  }
);

// 2. Get Worker by ID
app.get("/api/worker/:id", async (req, res) => {
  try {
    const [rows] = await db.query("SELECT * FROM workers WHERE id = ?", [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ error: "Worker not found" });

    const worker = rows[0];
    const toBase64 = (buffer) => (buffer ? buffer.toString("base64") : null);

    res.json({
      ...worker,
      cnicFront: toBase64(worker.cnicFront),
      cnicBack: toBase64(worker.cnicBack),
      profilePic: toBase64(worker.profilePic),
      workCert: toBase64(worker.workCert),
      license: toBase64(worker.license),
      licenseBack: toBase64(worker.licenseBack),
    });
  } catch (err) {
    console.error("❌ Fetch worker error:", err);
    res.status(500).json({ error: "Failed to fetch worker" });
  }
});

// 3. Update Worker Document
app.put(
  "/api/worker/:id/documents",
  upload.single("file"),
  async (req, res) => {
    const { id } = req.params;
    const { field } = req.query;
    const file = req.file;
    if (!field || !ALLOWED_FILE_FIELDS.includes(field)) {
      return res.status(400).json({ error: `Invalid 'field' query.` });
    }
    if (!file) {
      return res.status(400).json({ error: "No file uploaded" });
    }

    try {
      const sql = `UPDATE workers SET ${field} = ? WHERE id = ?`;
      const [result] = await db.query(sql, [file.buffer, id]);
      if (result.affectedRows === 0) return res.status(404).json({ error: "Worker not found" });
      res.json({ message: "Document updated successfully" });
    } catch (err) {
      console.error("❌ Error updating document:", err);
      res.status(500).json({ error: "Server error while updating document" });
    }
  }
);

// 4. Delete Worker Document
app.delete("/api/worker/:id/documents", async (req, res) => {
  const { id } = req.params;
  const { field } = req.query;
  if (!field || !ALLOWED_FILE_FIELDS.includes(field)) {
    return res.status(400).json({ error: `Invalid 'field' query.` });
  }

  try {
    const sql = `UPDATE workers SET ${field} = NULL WHERE id = ?`;
    const [result] = await db.query(sql, [id]);
    if (result.affectedRows === 0) return res.status(404).json({ error: "Worker not found" });
    res.json({ message: "File deleted successfully" });
  } catch (err) {
    console.error("❌ Error deleting document:", err);
    res.status(500).json({ error: "Server error" });
  }
});

// ================== JOB ROUTES ==================
// 1. POST: Customer Posts a Job
app.post('/api/jobs', async (req, res) => {
    try {
        const { customerId, title, description, budget, location } = req.body;

        // --- FIX: Use the actual customerId from the request ---
        if (!customerId || !title || !description || !budget) {
            return res.status(400).json({ error: "Customer ID and all job fields are required." });
        }

        const sql = `INSERT INTO jobs (customer_id, title, description, budget, location) VALUES (?, ?, ?, ?, ?)`;
        const [result] = await db.query(sql, [customerId, title, description, budget, location]);

        res.status(201).json({ message: "Job Posted Successfully", jobId: result.insertId });
    } catch (err) {
        console.error("❌ Job post error:", err);
        res.status(500).json({ error: "Database error" });
    }
});


// 3. PUT: Worker Accepts a Job
app.put('/api/jobs/:id/accept', async (req, res) => {
    const jobId = req.params.id;
    const { workerId } = req.body;
    if (!workerId) {
        return res.status(400).json({ error: "Worker ID is required to accept a job." });
    }
    try {
        const sql = `UPDATE jobs SET status = 'assigned', worker_id = ? WHERE id = ? AND status = 'open'`;
        const [result] = await db.query(sql, [workerId, jobId]);
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: "Job not found or already assigned." });
        }
        res.json({ message: "Job Accepted!" });
    } catch (err) {
        console.error("Error accepting job:", err);
        return res.status(500).json({ error: "Database update failed" });
    }
});

// GET: Admin sees all applications/earnings stats
app.get('/api/admin/earnings', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT
        ja.status,
        j.budget,
        j.title,
        w.fullName as workerName,
        c.fullName as customerName,
        ja.created_at
      FROM job_applications ja
      JOIN jobs j ON ja.job_id = j.id
      JOIN workers w ON ja.worker_id = w.id
      JOIN customers c ON j.customer_id = c.id
      WHERE ja.status = 'accepted'
      ORDER BY ja.created_at DESC
    `);

    const totalEarnings = rows.reduce(
      (sum, r) => sum + parseFloat(r.budget), 0
    );

    res.json({
      totalEarnings,
      totalAcceptedJobs: rows.length,
      transactions: rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// 2. GET: Worker Sees All Open Jobs with Customer Details
app.get('/api/jobs/open', async (req, res) => {
    try {
        const sql = `
            SELECT
                j.id, j.title, j.description, j.budget, j.location, j.created_at,
                c.fullName AS customerName,
                c.phone AS customerPhone,
                c.profilePic AS customerPic
            FROM jobs AS j
            INNER JOIN customers AS c ON j.customer_id = c.id
            WHERE j.status = 'open'
            ORDER BY j.created_at DESC
        `;
        const [rows] = await db.query(sql);

        // --- FIX: Correctly map and convert buffer to base64 ---
        const jobsWithPics = rows.map(job => ({
            ...job,
            customerPic: job.customerPic ? Buffer.from(job.customerPic).toString('base64') : null
        }));
        res.json(jobsWithPics);
    } catch (err) {
        console.error("❌ Fetch open jobs error:", err);
        res.status(500).json({ error: "Failed to fetch jobs" });
    }
});

// 4. GET: Fetch jobs posted by a specific customer
app.get('/api/jobs/customer/:id', async (req, res) => {
    const customerId = req.params.id;
    try {
        const sql = `SELECT * FROM jobs WHERE customer_id = ? ORDER BY created_at DESC`;
        const [rows] = await db.query(sql, [customerId]);
        res.json(rows);
    } catch (err) {
        console.error("Error fetching customer jobs:", err);
        res.status(500).json({ error: "Database error" });
    }
});

// GET: Find workers by skill (for chatbot)
app.get('/api/workers/search', async (req, res) => {
    try {
        const { skill, city } = req.query;

        let sql = `
            SELECT id, fullName, phone, city, skill, availableHours, about
            FROM workers
            WHERE worker_form_completed = 1
        `;
        const params = [];

        if (skill) {
            sql += ` AND skill LIKE ?`;
            params.push(`%${skill}%`);
        }
        if (city) {
            sql += ` AND city LIKE ?`;
            params.push(`%${city}%`);
        }

        sql += ` LIMIT 5`;

        const [rows] = await db.query(sql, params);
        res.json(rows);
    } catch (err) {
        console.error("❌ Worker search error:", err);
        res.status(500).json({ error: "Failed to search workers" });
    }
});

// ================== ADMIN ROUTES ==================

// GET all workers (no images for speed)
app.get('/api/admin/workers', async (req, res) => {
    try {
        const [rows] = await db.query(
            'SELECT id, fullName, cnic, phone, city, skill, availableHours, about, worker_form_completed, created_at FROM workers ORDER BY created_at DESC'
        );
        res.json(rows);
    } catch(err) { res.status(500).json({ error: err.message }) }
});

// GET all customers (no images for speed)
app.get('/api/admin/customers', async (req, res) => {
    try {
        const [rows] = await db.query(
            'SELECT id, fullName, cnic, phone, city, created_at FROM customers ORDER BY created_at DESC'
        );
        res.json(rows);
    } catch(err) { res.status(500).json({ error: err.message }) }
});

// GET all jobs with customer name
app.get('/api/admin/jobs', async (req, res) => {
    try {
        const [rows] = await db.query(`
            SELECT j.*, c.fullName AS customerName
            FROM jobs j
            LEFT JOIN customers c ON j.customer_id = c.id
            ORDER BY j.created_at DESC
        `);
        res.json(rows);
    } catch(err) { res.status(500).json({ error: err.message }) }
});

// DELETE worker
app.delete('/api/admin/worker/:id', async (req, res) => {
    try {
        await db.query('DELETE FROM workers WHERE id = ?', [req.params.id]);
        res.json({ message: 'Worker deleted' });
    } catch(err) { res.status(500).json({ error: err.message }) }
});

// DELETE customer
app.delete('/api/admin/customer/:id', async (req, res) => {
    try {
        await db.query('DELETE FROM customers WHERE id = ?', [req.params.id]);
        res.json({ message: 'Customer deleted' });
    } catch(err) { res.status(500).json({ error: err.message }) }
});

// DELETE job
app.delete('/api/admin/job/:id', async (req, res) => {
    try {
        await db.query('DELETE FROM jobs WHERE id = ?', [req.params.id]);
        res.json({ message: 'Job deleted' });
    } catch(err) { res.status(500).json({ error: err.message }) }
});

// VERIFY / UNVERIFY worker
app.put('/api/admin/worker/:id/verify', async (req, res) => {
    try {
        const { verified } = req.body;
        await db.query('UPDATE workers SET worker_form_completed = ? WHERE id = ?', [verified, req.params.id]);
        res.json({ message: 'Worker status updated' });
    } catch(err) { res.status(500).json({ error: err.message }) }
});

// ================== APPLICATIONS & MESSAGING ==================

// Worker applies to a job
app.post('/api/jobs/:id/apply', async (req, res) => {
  const { workerId } = req.body;
  const jobId = req.params.id;
  try {
    // Check if already applied
    const [existing] = await db.query(
      'SELECT id FROM job_applications WHERE job_id=? AND worker_id=?',
      [jobId, workerId]
    );
    if (existing.length > 0) {
      return res.status(400).json({ error: 'Already applied' });
    }
    const [result] = await db.query(
      'INSERT INTO job_applications (job_id, worker_id) VALUES (?,?)',
      [jobId, workerId]
    );
    res.status(201).json({ applicationId: result.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get applications for a job (customer sees who applied)
app.get('/api/jobs/:id/applications', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT ja.*, w.fullName, w.phone, w.skill, w.city,
             w.availableHours, w.about, w.profilePic
      FROM job_applications ja
      JOIN workers w ON ja.worker_id = w.id
      WHERE ja.job_id = ?
      ORDER BY ja.created_at DESC
    `, [req.params.id]);

    const result = rows.map(r => ({
      ...r,
      profilePic: r.profilePic ? Buffer.from(r.profilePic).toString('base64') : null
    }));
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Customer accepts/rejects application
app.put('/api/applications/:id', async (req, res) => {
  const { status } = req.body; // 'accepted' or 'rejected'
  try {
    await db.query(
      'UPDATE job_applications SET status=? WHERE id=?',
      [status, req.params.id]
    );
    res.json({ message: 'Application updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get worker's applications (worker sees jobs he applied to)
app.get('/api/worker/:id/applications', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT ja.*, j.title, j.description, j.budget,
             j.location, j.status as jobStatus,
             j.customer_id,
             c.fullName as customerName, c.phone as customerPhone
      FROM job_applications ja
      JOIN jobs j ON ja.job_id = j.id
      JOIN customers c ON j.customer_id = c.id
      WHERE ja.worker_id = ?
      ORDER BY ja.created_at DESC
    `, [req.params.id]);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Send a message
app.post('/api/messages', async (req, res) => {
  const { job_id, sender_type, sender_id, receiver_id, message } = req.body;
  try {
    const [result] = await db.query(
      'INSERT INTO messages (job_id, sender_type, sender_id, receiver_id, message) VALUES (?,?,?,?,?)',
      [job_id, sender_type, sender_id, receiver_id, message]
    );
    res.status(201).json({ messageId: result.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get messages for a job between worker and customer
app.get('/api/messages/:jobId/:workerId/:customerId', async (req, res) => {
  const { jobId, workerId, customerId } = req.params;
  try {
    const [rows] = await db.query(`
      SELECT * FROM messages
      WHERE job_id = ?
        AND ((sender_id = ? AND receiver_id = ?)
          OR (sender_id = ? AND receiver_id = ?))
      ORDER BY created_at ASC
    `, [jobId, workerId, customerId, customerId, workerId]);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Mark messages as read
app.put('/api/messages/read', async (req, res) => {
  const { job_id, receiver_id } = req.body;
  try {
    await db.query(
      'UPDATE messages SET is_read=1 WHERE job_id=? AND receiver_id=?',
      [job_id, receiver_id]
    );
    res.json({ message: 'Marked as read' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all conversations for a worker
app.get('/api/worker/:id/conversations', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT DISTINCT
        m.job_id, j.title as jobTitle,
        c.id as customerId, c.fullName as customerName,
        c.phone as customerPhone,
        (SELECT message FROM messages m2
         WHERE m2.job_id = m.job_id ORDER BY m2.created_at DESC LIMIT 1) as lastMessage,
        (SELECT created_at FROM messages m2
         WHERE m2.job_id = m.job_id ORDER BY m2.created_at DESC LIMIT 1) as lastTime,
        (SELECT COUNT(*) FROM messages m2
         WHERE m2.job_id = m.job_id
           AND m2.receiver_id = ? AND m2.is_read = 0) as unreadCount
      FROM messages m
      JOIN jobs j ON m.job_id = j.id
      JOIN customers c ON j.customer_id = c.id
      WHERE (m.sender_id = ? AND m.sender_type = 'worker')
         OR (m.receiver_id = ? AND m.sender_type = 'customer')
      GROUP BY m.job_id
      ORDER BY lastTime DESC
    `, [req.params.id, req.params.id, req.params.id]);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all conversations for a customer
app.get('/api/customer/:id/conversations', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT DISTINCT
        m.job_id, j.title as jobTitle,
        w.id as workerId, w.fullName as workerName,
        w.phone as workerPhone, w.skill as workerSkill,
        (SELECT message FROM messages m2
         WHERE m2.job_id = m.job_id ORDER BY m2.created_at DESC LIMIT 1) as lastMessage,
        (SELECT created_at FROM messages m2
         WHERE m2.job_id = m.job_id ORDER BY m2.created_at DESC LIMIT 1) as lastTime,
        (SELECT COUNT(*) FROM messages m2
         WHERE m2.job_id = m.job_id
           AND m2.receiver_id = ? AND m2.is_read = 0) as unreadCount
      FROM messages m
      JOIN jobs j ON m.job_id = j.id
      JOIN workers w ON (m.sender_id = w.id AND m.sender_type = 'worker')
                     OR (m.receiver_id = w.id AND m.sender_type = 'customer')
      WHERE j.customer_id = ?
      GROUP BY m.job_id, w.id
      ORDER BY lastTime DESC
    `, [req.params.id, req.params.id]);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ================== LOGIN SYSTEM (Phone Only) ==================

app.post('/api/login', async (req, res) => {
  const { phone } = req.body;

  if (!phone) {
    return res.status(400).json({ error: "Phone number is required" });
  }

  try {
    // Check workers table first
    const [workerRows] = await db.query(
      'SELECT id, fullName FROM workers WHERE phone = ?',
      [phone]
    );

    if (workerRows.length > 0) {
      return res.json({
        success: true,
        role: 'worker',
        id: workerRows[0].id,
        fullName: workerRows[0].fullName,
      });
    }

    // Check customers table
    const [customerRows] = await db.query(
      'SELECT id, fullName FROM customers WHERE phone = ?',
      [phone]
    );

    if (customerRows.length > 0) {
      return res.json({
        success: true,
        role: 'customer',
        id: customerRows[0].id,
        fullName: customerRows[0].fullName,
      });
    }

    // Not found in either table
    return res.status(404).json({
      error: "No account found with this phone number. Please register first."
    });

  } catch (err) {
    console.error("❌ Login error:", err);
    res.status(500).json({ error: "Server error during login" });
  }
});

// ================== GPS & LOCATION ==================

// Update worker location
app.put('/api/worker/:id/location', async (req, res) => {
  const { latitude, longitude } = req.body;
  try {
    await db.query(
      'UPDATE workers SET latitude=?, longitude=? WHERE id=?',
      [latitude, longitude, req.params.id]
    );
    res.json({ message: 'Location updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get nearby workers by skill and distance
app.get('/api/workers/nearby', async (req, res) => {
  const { latitude, longitude, skill, radius = 50 } = req.query;
  try {
    let sql = `
      SELECT id, fullName, phone, skill, city, availableHours,
             avg_rating, total_ratings, latitude, longitude,
             (6371 * acos(
               cos(radians(?)) * cos(radians(latitude)) *
               cos(radians(longitude) - radians(?)) +
               sin(radians(?)) * sin(radians(latitude))
             )) AS distance
      FROM workers
      WHERE worker_form_completed = 1
        AND latitude IS NOT NULL
        AND longitude IS NOT NULL
    `;
    const params = [latitude, longitude, latitude];

    if (skill) {
      sql += ` AND skill LIKE ?`;
      params.push(`%${skill}%`);
    }

    sql += ` HAVING distance < ? ORDER BY distance ASC LIMIT 20`;
    params.push(radius);

    const [rows] = await db.query(sql, params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get nearby jobs
app.get('/api/jobs/nearby', async (req, res) => {
  const { latitude, longitude, radius = 50 } = req.query;
  try {
    const sql = `
      SELECT j.*, c.fullName AS customerName, c.phone AS customerPhone,
             (6371 * acos(
               cos(radians(?)) * cos(radians(j.latitude)) *
               cos(radians(j.longitude) - radians(?)) +
               sin(radians(?)) * sin(radians(j.latitude))
             )) AS distance
      FROM jobs j
      JOIN customers c ON j.customer_id = c.id
      WHERE j.status = 'open'
        AND j.latitude IS NOT NULL
        AND j.longitude IS NOT NULL
      HAVING distance < ?
      ORDER BY distance ASC
      LIMIT 20
    `;
    const [rows] = await db.query(sql,
      [latitude, longitude, latitude, radius]);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ================== RATINGS ==================

// Submit rating
app.post('/api/ratings', async (req, res) => {
  const { job_id, rated_by, rater_id, rated_id, rating, feedback } = req.body;
  try {
    // Check if already rated
    const [existing] = await db.query(
      'SELECT id FROM ratings WHERE job_id=? AND rated_by=? AND rater_id=?',
      [job_id, rated_by, rater_id]
    );
    if (existing.length > 0) {
      return res.status(400).json({ error: 'Already rated' });
    }

    await db.query(
      'INSERT INTO ratings (job_id, rated_by, rater_id, rated_id, rating, feedback) VALUES (?,?,?,?,?,?)',
      [job_id, rated_by, rater_id, rated_id, rating, feedback || null]
    );

    // Update average rating
    if (rated_by === 'customer') {
      // Worker was rated by customer
      await db.query(`
        UPDATE workers SET
          avg_rating = (SELECT AVG(rating) FROM ratings WHERE rated_id=? AND rated_by='customer'),
          total_ratings = (SELECT COUNT(*) FROM ratings WHERE rated_id=? AND rated_by='customer')
        WHERE id=?
      `, [rated_id, rated_id, rated_id]);
    } else {
      // Customer was rated by worker
      await db.query(`
        UPDATE customers SET
          avg_rating = (SELECT AVG(rating) FROM ratings WHERE rated_id=? AND rated_by='worker'),
          total_ratings = (SELECT COUNT(*) FROM ratings WHERE rated_id=? AND rated_by='worker')
        WHERE id=?
      `, [rated_id, rated_id, rated_id]);
    }

    res.status(201).json({ message: 'Rating submitted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Check if rated
app.get('/api/ratings/check', async (req, res) => {
  const { job_id, rated_by, rater_id } = req.query;
  try {
    const [rows] = await db.query(
      'SELECT id FROM ratings WHERE job_id=? AND rated_by=? AND rater_id=?',
      [job_id, rated_by, rater_id]
    );
    res.json({ hasRated: rows.length > 0 });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Mark job as completed
app.put('/api/jobs/:id/complete', async (req, res) => {
  try {
    await db.query(
      "UPDATE jobs SET status='completed' WHERE id=?",
      [req.params.id]
    );
    res.json({ message: 'Job marked as completed' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get job status
app.get('/api/jobs/:id/status', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id, status, worker_id, customer_id FROM jobs WHERE id=?',
      [req.params.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Job not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ================== START SERVER ==================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`✅ Server running on port ${PORT}. All routes registered.`));
