<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, doa.DBConnection" %>
<%
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=Please login first");
        return;
    }
    String idStr = request.getParameter("id");
    if (idStr == null || idStr.trim().isEmpty()) {
        response.sendRedirect("view_dealers.jsp");
        return;
    }
    int dealerId = Integer.parseInt(idStr.trim());
    String dealerName  = "";
    String dealerPhone = "";
    double dealerCredit = 0;

    try (Connection conn = DBConnection.getConnection()) {
        PreparedStatement ps = conn.prepareStatement(
            "SELECT name, phone, credit FROM dealers WHERE id = ?");
        ps.setInt(1, dealerId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            dealerName  = rs.getString("name");
            dealerPhone = rs.getString("phone");
            dealerCredit = rs.getDouble("credit");
        } else {
            response.sendRedirect("view_dealers.jsp?error=Dealer not found");
            return;
        }
    } catch (Exception e) {
        response.sendRedirect("view_dealers.jsp?error=" + e.getMessage());
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Settle Credit — <%= dealerName %></title>
    <link rel="stylesheet" href="css/content.css">
    <style>
        /* ── Dealer Info Banner ── */
        .dealer-card {
            background: linear-gradient(135deg, #7a3800 0%, #d4681a 100%);
            color: #fff;
            border-radius: 14px;
            padding: 20px 26px;
            margin-bottom: 24px;
            display: flex;
            align-items: center;
            gap: 20px;
            flex-wrap: wrap;
            box-shadow: 0 6px 20px rgba(0,0,0,0.18);
        }
        .dealer-card .avatar {
            width: 56px; height: 56px;
            background: rgba(255,255,255,0.15);
            border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            font-size: 26px;
            border: 2px solid rgba(255,255,255,0.3);
            flex-shrink: 0;
        }
        .dealer-card .cinfo { flex: 1; }
        .dealer-card .cinfo h3 { font-size: 18px; font-weight: 700; margin: 0 0 4px; }
        .dealer-card .cinfo p  { font-size: 13px; color: #ffd8b0; margin: 0; }
        .dealer-card .credit-pill {
            background: rgba(255,255,255,0.13);
            border: 1px solid rgba(255,255,255,0.25);
            border-radius: 10px;
            padding: 10px 20px;
            text-align: center;
        }
        .dealer-card .credit-pill .lbl {
            font-size: 11px; color: #ffd0a0;
            text-transform: uppercase; letter-spacing: 0.8px;
        }
        .dealer-card .credit-pill .val {
            font-size: 20px; font-weight: 800; color: #ffcdd2; margin-top: 2px;
        }

        /* ── Payment Mode Radio Group ── */
        .payment-mode-group {
            display: flex;
            gap: 16px;
            margin-top: 4px;
            flex-wrap: wrap;
        }
        .payment-option {
            flex: 1;
            min-width: 130px;
            position: relative;
        }
        .payment-option input[type="radio"] {
            position: absolute;
            opacity: 0;
            width: 0; height: 0;
        }
        .payment-option label {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            padding: 14px 18px;
            border: 2px solid #f5c6a0;
            border-radius: 10px;
            background: #fff;
            cursor: pointer;
            font-size: 15px;
            font-weight: 700;
            color: #7a3800;
            transition: all 0.2s;
            user-select: none;
        }
        .payment-option label .mode-icon { font-size: 22px; }
        .payment-option input[type="radio"]:checked + label {
            border-color: #d4681a;
            background: linear-gradient(135deg, #fff3e0, #ffe0b2);
            color: #7a3800;
            box-shadow: 0 0 0 3px rgba(212,104,26,0.15);
        }
        .payment-option label:hover {
            border-color: #f5a623;
            background: #fff8f0;
        }

        /* ── Warning strip if credit is 0 ── */
        .zero-credit-warn {
            background: #fff8e1;
            border-left: 4px solid #f5a623;
            border-radius: 0 8px 8px 0;
            padding: 10px 16px;
            font-size: 13px;
            color: #7a5c00;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
    </style>
</head>
<body>

<div class="content-wrapper">

    <% if (request.getParameter("error") != null) { %>
    <div class="alert alert-error">❌ <%= request.getParameter("error") %></div>
    <% } %>

    <!-- Back link -->
    <a href="view_dealers.jsp" class="back-link">← Back to Dealers</a>

    <% if (dealerCredit <= 0) { %>
    <div class="zero-credit-warn">
        ⚠️ <strong>No outstanding credit.</strong>
        This dealer has ₹ <%= String.format("%.2f", dealerCredit) %> — nothing to settle.
    </div>
    <% } %>

    <!-- Dealer Info Banner -->
    <div class="dealer-card">
        <div class="avatar">🏬</div>
        <div class="cinfo">
            <h3><%= dealerName %></h3>
            <p>📞 <%= dealerPhone %> &nbsp;|&nbsp; Dealer ID #<%= dealerId %></p>
        </div>
        <div class="credit-pill">
            <div class="lbl">Outstanding Credit</div>
            <div class="val">₹ <%= String.format("%.2f", dealerCredit) %></div>
        </div>
    </div>

    <!-- Settle Form -->
    <div class="form-container" style="padding: 0; max-width: 620px;">
        <form action="SettleDealerCreditServlet" method="post" onsubmit="return validateForm()">
            <input type="hidden" name="id" value="<%= dealerId %>">

            <fieldset>
                <legend>Settle Credit Payment</legend>

                <div class="form-grid">

                    <!-- Settle Amount -->
                    <div class="form-group full-width">
                        <label for="settleAmount">💰 Settlement Amount (₹)
                            <span style="color:#e53935;">*</span>
                        </label>
                        <input type="number" id="settleAmount" name="settleAmount"
                               placeholder="0.00" step="0.01" min="0.01"
                               max="<%= dealerCredit %>"
                               required
                               oninput="updatePreview(this)">
                        <div id="amountHint" style="font-size:12px; color:#888; margin-top:4px;">
                            Max: ₹ <%= String.format("%.2f", dealerCredit) %>
                        </div>
                    </div>

                    <!-- Payment Mode -->
                    <div class="form-group full-width">
                        <label>💳 Payment Mode <span style="color:#e53935;">*</span></label>
                        <div class="payment-mode-group">

                            <div class="payment-option">
                                <input type="radio" id="modeCash" name="paymentMode"
                                       value="CASH" required checked>
                                <label for="modeCash">
                                    <span class="mode-icon">💵</span> Cash
                                </label>
                            </div>

                            <div class="payment-option">
                                <input type="radio" id="modeOnline" name="paymentMode"
                                       value="ONLINE">
                                <label for="modeOnline">
                                    <span class="mode-icon">📱</span> Online
                                </label>
                            </div>

                        </div>
                    </div>

                    <!-- Live preview -->
                    <div class="form-group full-width">
                        <div id="previewBar" style="display:none; background:#e8f5e9;
                             border:1px solid #a5d6a7; border-radius:8px;
                             padding:10px 16px; font-size:13px; color:#1b5e20; font-weight:600;">
                            After settlement, remaining credit will be:
                            <strong id="previewVal">—</strong>
                        </div>
                    </div>

                </div>
            </fieldset>

            <div class="form-buttons">
                <button type="submit" class="btn-save"
                        style="background: linear-gradient(135deg,#e53935,#b71c1c);"
                        <%= dealerCredit <= 0 ? "disabled" : "" %>>
                    ✅ Settle Credit
                </button>
                <a href="view_dealers.jsp" class="btn-clear"
                   style="text-decoration:none; display:inline-flex;
                          align-items:center; justify-content:center;">
                    Cancel
                </a>
            </div>
        </form>
    </div>

</div>

<script>
var maxCredit = <%= dealerCredit %>;

function updatePreview(inp) {
    var val = parseFloat(inp.value);
    var bar = document.getElementById('previewBar');
    var pv  = document.getElementById('previewVal');
    if (!isNaN(val) && val > 0) {
        var remaining = Math.max(0, maxCredit - val).toFixed(2);
        pv.textContent = '₹ ' + remaining;
        bar.style.display = 'block';
    } else {
        bar.style.display = 'none';
    }
}

function validateForm() {
    var amt  = parseFloat(document.getElementById('settleAmount').value);
    var mode = document.querySelector('input[name="paymentMode"]:checked');

    if (!amt || amt <= 0) {
        alert('⚠️ Please enter a valid settlement amount.');
        return false;
    }
    if (amt > maxCredit) {
        alert('⚠️ Amount exceeds outstanding credit (₹ ' + maxCredit.toFixed(2) + ').');
        return false;
    }
    if (!mode) {
        alert('⚠️ Please select a payment mode (Cash or Online).');
        return false;
    }
    return true;
}
</script>
</body>
</html>
