<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="doa.AESEncryption, doa.DBConnection, doa.ShopConfig" %>
<%@ page import="java.sql.*" %>
<%
    /* ── Guard: only allow access if admin is logged in ── */
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=Please login first");
        return;
    }

    String action    = request.getParameter("action");
    String plainText = request.getParameter("plainText");
    String cipherText= request.getParameter("cipherText");

    String encryptedResult = null;
    String decryptedResult = null;
    String savedUsername   = null;
    String savedPassword   = null;

    String successMsg = null;
    String errorMsg   = null;

    /* ── ENCRYPT ── */
    if ("encrypt".equals(action) && plainText != null && !plainText.trim().isEmpty()) {
        try {
            encryptedResult = AESEncryption.encrypt(plainText.trim());
        } catch (Exception e) {
            errorMsg = "Encryption failed: " + e.getMessage();
        }
    }

    /* ── DECRYPT ── */
    if ("decrypt".equals(action) && cipherText != null && !cipherText.trim().isEmpty()) {
        try {
            decryptedResult = AESEncryption.decrypt(cipherText.trim());
        } catch (Exception e) {
            errorMsg = "Decryption failed: " + e.getMessage();
        }
    }

    /* ── SAVE TO DB ── */
    if ("save".equals(action)) {
        savedUsername = request.getParameter("saveUsername");
        savedPassword = request.getParameter("saveEncrypted");
        if (savedUsername != null && !savedUsername.trim().isEmpty()
                && savedPassword != null && !savedPassword.trim().isEmpty()) {
            try (Connection conn = DBConnection.getConnection()) {
                /* Check if user already exists */
                PreparedStatement chk = conn.prepareStatement(
                    "SELECT COUNT(*) FROM admin_users WHERE username = ?");
                chk.setString(1, savedUsername.trim());
                ResultSet chkRs = chk.executeQuery(); chkRs.next();
                boolean exists = chkRs.getInt(1) > 0;
                chkRs.close(); chk.close();

                if (exists) {
                    PreparedStatement upd = conn.prepareStatement(
                        "UPDATE admin_users SET password = ? WHERE username = ?");
                    upd.setString(1, savedPassword.trim());
                    upd.setString(2, savedUsername.trim());
                    upd.executeUpdate(); upd.close();
                    successMsg = "Password updated for user: " + savedUsername.trim();
                } else {
                    PreparedStatement ins = conn.prepareStatement(
                        "INSERT INTO admin_users (username, password, full_name, is_active) VALUES (?, ?, ?, 'Y')");
                    ins.setString(1, savedUsername.trim());
                    ins.setString(2, savedPassword.trim());
                    ins.setString(3, savedUsername.trim());
                    ins.executeUpdate(); ins.close();
                    successMsg = "New admin created: " + savedUsername.trim();
                }
            } catch (Exception e) {
                errorMsg = "Database error: " + e.getMessage();
            }
        } else {
            errorMsg = "Username and encrypted password are required to save.";
        }
    }

    ShopConfig shop   = ShopConfig.getInstance();
    String shopEnName = shop.getEnglishName();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Password Encryption — <%= shopEnName %></title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        /* ═══════════════════════════════════════════════
           BASE / RESET
        ═══════════════════════════════════════════════ */
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        :root {
            --navy-900: #060d1a;
            --navy-800: #0d1b2a;
            --navy-700: #162538;
            --navy-600: #1e3350;
            --navy-500: #2a4a72;
            --gold:     #f0a500;
            --gold-lt:  #fbbf24;
            --gold-dim: rgba(240,165,0,0.14);
            --green:    #00b87a;
            --red:      #ff4757;
            --white:    #ffffff;
            --muted:    rgba(255,255,255,0.55);
            --surface:  rgba(255,255,255,0.06);
            --border:   rgba(255,255,255,0.10);
            --font:     'Outfit', sans-serif;
        }

        html, body {
            min-height: 100vh;
            font-family: var(--font);
            background: var(--navy-800);
            color: var(--white);
        }

        /* ── Background mesh ── */
        body::before {
            content: '';
            position: fixed; inset: 0;
            background:
                radial-gradient(ellipse 80% 60% at 15% 10%,  rgba(240,165,0,0.07) 0%, transparent 60%),
                radial-gradient(ellipse 60% 80% at 85% 85%,  rgba(42,74,114,0.45) 0%, transparent 60%),
                linear-gradient(160deg, #060d1a 0%, #0d1b2a 45%, #162538 100%);
            z-index: 0; pointer-events: none;
        }
        body::after {
            content: '';
            position: fixed; inset: 0;
            background-image:
                linear-gradient(rgba(240,165,0,0.025) 1px, transparent 1px),
                linear-gradient(90deg, rgba(240,165,0,0.025) 1px, transparent 1px);
            background-size: 48px 48px;
            z-index: 0; pointer-events: none;
        }

        /* ── Layout ── */
        .page-layout {
            position: relative; z-index: 1;
            display: flex; flex-direction: column;
            align-items: center;
            padding: 36px 20px 60px;
            gap: 28px;
        }

        /* ── Header ── */
        .page-header {
            text-align: center;
            animation: fadeDown 0.65s cubic-bezier(0.22,1,0.36,1) both;
        }
        .header-icon {
            font-size: 48px; line-height: 1; display: block;
            filter: drop-shadow(0 4px 16px rgba(240,165,0,0.35));
            margin-bottom: 12px;
        }
        .header-title {
            font-size: 28px; font-weight: 800;
            letter-spacing: 1.8px; text-transform: uppercase;
            background: linear-gradient(135deg, #fff 30%, var(--gold) 100%);
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .header-sub {
            font-size: 13px; color: var(--muted);
            letter-spacing: 0.4px; margin-top: 5px;
        }

        /* ── Nav back button ── */
        .back-btn {
            position: fixed; top: 20px; left: 24px; z-index: 100;
            display: inline-flex; align-items: center; gap: 6px;
            padding: 8px 16px;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 10px;
            color: var(--muted);
            text-decoration: none;
            font-size: 13px; font-weight: 600;
            transition: all 0.2s;
        }
        .back-btn:hover { background: var(--gold-dim); border-color: rgba(240,165,0,0.3); color: var(--gold); }

        /* ── Grid ── */
        .cards-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            width: 100%; max-width: 900px;
            animation: fadeUp 0.65s cubic-bezier(0.22,1,0.36,1) 0.1s both;
        }
        @media (max-width: 720px) { .cards-grid { grid-template-columns: 1fr; } }

        /* ── Cards ── */
        .card {
            background: var(--surface);
            backdrop-filter: blur(20px) saturate(1.4);
            -webkit-backdrop-filter: blur(20px) saturate(1.4);
            border: 1px solid var(--border);
            border-radius: 20px;
            padding: 28px 28px 24px;
            box-shadow:
                0 0 0 1px rgba(240,165,0,0.05),
                0 24px 64px rgba(0,0,0,0.4),
                inset 0 1px 0 rgba(255,255,255,0.06);
            display: flex; flex-direction: column; gap: 18px;
        }
        .card-full {
            grid-column: span 2;
        }
        @media (max-width: 720px) { .card-full { grid-column: span 1; } }

        .card-title {
            display: flex; align-items: center; gap: 10px;
            font-size: 15px; font-weight: 700;
            color: rgba(255,255,255,0.88);
            padding-bottom: 14px;
            border-bottom: 1px solid var(--border);
        }
        .card-title .ct-icon {
            width: 36px; height: 36px;
            background: var(--gold-dim);
            border: 1px solid rgba(240,165,0,0.2);
            border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
            font-size: 17px; flex-shrink: 0;
        }

        /* ── Form elements ── */
        .field-group { display: flex; flex-direction: column; gap: 7px; }
        .field-group label {
            font-size: 11px; font-weight: 700;
            color: var(--muted);
            text-transform: uppercase; letter-spacing: 0.9px;
        }
        .field-group input,
        .field-group textarea {
            width: 100%;
            padding: 12px 15px;
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(255,255,255,0.11);
            border-radius: 11px;
            color: var(--white);
            font-family: var(--font);
            font-size: 14px; font-weight: 500;
            outline: none;
            transition: border-color 0.2s, background 0.2s, box-shadow 0.2s;
            resize: none;
        }
        .field-group input::placeholder,
        .field-group textarea::placeholder { color: rgba(255,255,255,0.22); }
        .field-group input:focus,
        .field-group textarea:focus {
            border-color: var(--gold);
            background: rgba(240,165,0,0.04);
            box-shadow: 0 0 0 3px rgba(240,165,0,0.10);
        }
        .field-group textarea { min-height: 80px; font-family: 'Courier New', monospace; font-size: 13px; }

        /* ── Result output box ── */
        .result-box {
            background: rgba(240,165,0,0.06);
            border: 1px solid rgba(240,165,0,0.2);
            border-radius: 11px;
            padding: 14px 16px;
            font-family: 'Courier New', monospace;
            font-size: 13px;
            color: var(--gold-lt);
            word-break: break-all;
            line-height: 1.6;
            position: relative;
        }
        .result-box .result-label {
            font-family: var(--font);
            font-size: 10px; font-weight: 700;
            color: var(--gold);
            text-transform: uppercase;
            letter-spacing: 0.8px;
            margin-bottom: 6px;
            display: block;
        }
        .result-box .result-value {
            display: block;
            user-select: all;
        }

        /* ── Copy button inside result ── */
        .btn-copy-inline {
            position: absolute; top: 10px; right: 10px;
            background: rgba(240,165,0,0.15);
            border: 1px solid rgba(240,165,0,0.3);
            border-radius: 7px;
            color: var(--gold);
            font-family: var(--font);
            font-size: 11px; font-weight: 700;
            padding: 4px 10px;
            cursor: pointer;
            transition: all 0.2s;
        }
        .btn-copy-inline:hover { background: var(--gold); color: var(--navy-900); }

        /* ── Buttons ── */
        .btn-primary {
            width: 100%;
            padding: 13px;
            background: linear-gradient(135deg, var(--gold) 0%, #c88200 100%);
            border: none; border-radius: 12px;
            color: var(--navy-900);
            font-family: var(--font);
            font-size: 14px; font-weight: 800;
            letter-spacing: 0.4px;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
            box-shadow: 0 6px 20px rgba(240,165,0,0.28);
        }
        .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 10px 28px rgba(240,165,0,0.38); }
        .btn-primary:active { transform: translateY(0); }

        .btn-green {
            width: 100%;
            padding: 13px;
            background: linear-gradient(135deg, #00b87a 0%, #007a52 100%);
            border: none; border-radius: 12px;
            color: #fff;
            font-family: var(--font);
            font-size: 14px; font-weight: 800;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
            box-shadow: 0 6px 20px rgba(0,184,122,0.25);
        }
        .btn-green:hover  { transform: translateY(-2px); box-shadow: 0 10px 28px rgba(0,184,122,0.35); }
        .btn-green:active { transform: translateY(0); }

        /* ── Alert messages ── */
        .alert {
            width: 100%; max-width: 900px;
            padding: 13px 18px;
            border-radius: 12px;
            font-size: 13.5px; font-weight: 600;
            display: flex; align-items: center; gap: 10px;
            animation: fadeUp 0.4s ease both;
        }
        .alert-success {
            background: rgba(0,184,122,0.12);
            border: 1px solid rgba(0,184,122,0.3);
            color: #6fffd4;
        }
        .alert-error {
            background: rgba(255,71,87,0.12);
            border: 1px solid rgba(255,71,87,0.3);
            color: #ff9aa5;
        }

        /* ── Info strip ── */
        .info-strip {
            display: flex; align-items: flex-start; gap: 10px;
            background: rgba(240,165,0,0.07);
            border: 1px solid rgba(240,165,0,0.15);
            border-radius: 10px;
            padding: 12px 15px;
            font-size: 12.5px;
            color: rgba(255,255,255,0.55);
            line-height: 1.55;
        }
        .info-strip strong { color: var(--gold); }

        /* ── Save section separator ── */
        .section-sep {
            display: flex; align-items: center; gap: 12px;
            color: var(--muted); font-size: 11px;
            text-transform: uppercase; letter-spacing: 1px; font-weight: 700;
        }
        .section-sep::before, .section-sep::after {
            content: ''; flex: 1; height: 1px;
            background: var(--border);
        }

        /* ── Animations ── */
        @keyframes fadeDown {
            from { opacity: 0; transform: translateY(-20px); }
            to   { opacity: 1; transform: translateY(0); }
        }
        @keyframes fadeUp {
            from { opacity: 0; transform: translateY(16px); }
            to   { opacity: 1; transform: translateY(0); }
        }

        /* ── Footer ── */
        .page-footer {
            font-size: 12px; color: rgba(255,255,255,0.2);
            letter-spacing: 0.3px;
        }
    </style>
</head>
<body>

<!-- Back to main app -->
<a href="main.jsp" class="back-btn">← Back</a>

<div class="page-layout">

    <!-- Header -->
    <div class="page-header">
        <span class="header-icon">🔐</span>
        <div class="header-title">Password Encryption</div>
        <div class="header-sub"><%= shopEnName %> · AES-256 Encryption Utility</div>
    </div>

    <!-- Alert Messages -->
    <% if (successMsg != null) { %>
    <div class="alert alert-success">✅ <%= successMsg %></div>
    <% } %>
    <% if (errorMsg != null) { %>
    <div class="alert alert-error">❌ <%= errorMsg %></div>
    <% } %>

    <!-- Cards Grid -->
    <div class="cards-grid">

        <!-- ══ ENCRYPT CARD ══ -->
        <div class="card">
            <div class="card-title">
                <div class="ct-icon">🔒</div>
                <span>Encrypt Plain Text</span>
            </div>

            <div class="info-strip">
                <span>ℹ️</span>
                <span>Enter a <strong>plain text password</strong> to generate its AES-256 encrypted value. Use this before saving admin credentials to the database.</span>
            </div>

            <form action="encrypt_password.jsp" method="post">
                <input type="hidden" name="action" value="encrypt">
                <div class="field-group" style="margin-bottom:14px;">
                    <label for="plainText">Plain Text / Password</label>
                    <input type="password" id="plainText" name="plainText"
                           placeholder="Enter password to encrypt"
                           value="<%= plainText != null ? plainText : "" %>">
                </div>
                <button type="submit" class="btn-primary">🔒 Encrypt Now</button>
            </form>

            <% if (encryptedResult != null) { %>
            <div class="result-box">
                <span class="result-label">Encrypted Output</span>
                <span class="result-value" id="encResult"><%= encryptedResult %></span>
                <button class="btn-copy-inline" onclick="copyText('encResult', this)">Copy</button>
            </div>

            <!-- Save to DB -->
            <div class="section-sep">Save to Database</div>

            <form action="encrypt_password.jsp" method="post" style="display:flex; flex-direction:column; gap:12px;">
                <input type="hidden" name="action"        value="save">
                <input type="hidden" name="saveEncrypted" value="<%= encryptedResult %>">
                <div class="field-group">
                    <label for="saveUsername">Admin Username to Update</label>
                    <input type="text" id="saveUsername" name="saveUsername"
                           placeholder="e.g. admin"
                           value="<%= savedUsername != null ? savedUsername : "" %>">
                </div>
                <button type="submit" class="btn-green">💾 Save to Database</button>
            </form>
            <% } %>
        </div>

        <!-- ══ DECRYPT CARD ══ -->
        <div class="card">
            <div class="card-title">
                <div class="ct-icon">🔓</div>
                <span>Decrypt Cipher Text</span>
            </div>

            <div class="info-strip">
                <span>ℹ️</span>
                <span>Paste an <strong>encrypted (Base64) string</strong> to reveal its original plain text. Useful for verifying stored passwords.</span>
            </div>

            <form action="encrypt_password.jsp" method="post">
                <input type="hidden" name="action" value="decrypt">
                <div class="field-group" style="margin-bottom:14px;">
                    <label for="cipherText">Encrypted / Cipher Text</label>
                    <textarea id="cipherText" name="cipherText"
                              placeholder="Paste Base64-encoded cipher text here…"><%= cipherText != null ? cipherText : "" %></textarea>
                </div>
                <button type="submit" class="btn-primary" style="background:linear-gradient(135deg,#3b82f6,#1e40af); box-shadow:0 6px 20px rgba(59,130,246,0.28);">
                    🔓 Decrypt Now
                </button>
            </form>

            <% if (decryptedResult != null) { %>
            <div class="result-box" style="border-color:rgba(59,130,246,0.3); background:rgba(59,130,246,0.06);">
                <span class="result-label" style="color:#93c5fd;">Decrypted Result</span>
                <span class="result-value" id="decResult" style="color:#bfdbfe;"><%= decryptedResult %></span>
                <button class="btn-copy-inline" style="border-color:rgba(59,130,246,0.4); color:#93c5fd; background:rgba(59,130,246,0.12);"
                        onclick="copyText('decResult', this)">Copy</button>
            </div>
            <% } %>
        </div>

        <!-- ══ REFERENCE CARD (full-width) ══ -->
        <div class="card card-full">
            <div class="card-title">
                <div class="ct-icon">📖</div>
                <span>Quick Reference</span>
            </div>
            <div style="display:grid; grid-template-columns:repeat(3,1fr); gap:14px; flex-wrap:wrap;">

                <div style="background:rgba(255,255,255,0.04); border:1px solid var(--border); border-radius:12px; padding:16px;">
                    <div style="font-size:11px; font-weight:700; color:var(--gold); text-transform:uppercase; letter-spacing:0.8px; margin-bottom:8px;">Algorithm</div>
                    <div style="font-size:14px; font-weight:700; color:rgba(255,255,255,0.85);">AES-256</div>
                    <div style="font-size:12px; color:var(--muted); margin-top:4px;">Advanced Encryption Standard · 256-bit key</div>
                </div>

                <div style="background:rgba(255,255,255,0.04); border:1px solid var(--border); border-radius:12px; padding:16px;">
                    <div style="font-size:11px; font-weight:700; color:var(--gold); text-transform:uppercase; letter-spacing:0.8px; margin-bottom:8px;">Output Format</div>
                    <div style="font-size:14px; font-weight:700; color:rgba(255,255,255,0.85);">Base64</div>
                    <div style="font-size:12px; color:var(--muted); margin-top:4px;">Encrypted bytes encoded as Base64 string</div>
                </div>

                <div style="background:rgba(255,255,255,0.04); border:1px solid var(--border); border-radius:12px; padding:16px;">
                    <div style="font-size:11px; font-weight:700; color:var(--gold); text-transform:uppercase; letter-spacing:0.8px; margin-bottom:8px;">Usage</div>
                    <div style="font-size:14px; font-weight:700; color:rgba(255,255,255,0.85);">Admin Passwords</div>
                    <div style="font-size:12px; color:var(--muted); margin-top:4px;">Stored encrypted in <code style="color:var(--gold-lt);">admin_users</code> table</div>
                </div>

            </div>

            <div class="info-strip" style="margin-top:4px;">
                ⚠️&nbsp;
                <span style="color:rgba(255,255,255,0.5);">
                    <strong style="color:#f87171;">Security Note:</strong>
                    Never share the secret key or the plain-text password. This page is for administrators only.
                    Ensure <code style="color:var(--gold-lt);">encrypt_password.jsp</code> is accessible only to logged-in admins.
                </span>
            </div>
        </div>

    </div>

    <div class="page-footer">© <%= new java.util.Date().getYear() + 1900 %> <%= shopEnName %> · Password Encryption Utility</div>

</div>

<script>
function copyText(elemId, btn) {
    var el  = document.getElementById(elemId);
    var txt = el.textContent.trim();
    var orig = btn.textContent;
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(txt).then(function() { flash(btn, orig); });
    } else {
        var ta = document.createElement('textarea');
        ta.value = txt; ta.style.position = 'fixed'; ta.style.opacity = '0';
        document.body.appendChild(ta); ta.select();
        document.execCommand('copy');
        document.body.removeChild(ta);
        flash(btn, orig);
    }
}
function flash(btn, orig) {
    btn.textContent = '✓ Copied!';
    setTimeout(function() { btn.textContent = orig; }, 2200);
}
</script>

</body>
</html>
