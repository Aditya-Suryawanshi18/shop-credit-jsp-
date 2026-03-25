<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=Please login first");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Add Customer</title>
    <link rel="stylesheet" href="css/content.css">
    <style>
        .form-page-header {
            background: linear-gradient(135deg, #0d1b2a, #162538);
            color: #fff;
            padding: 20px 26px;
            display: flex; align-items: center; gap: 14px;
            margin-bottom: 0;
        }
        .form-page-header .fph-icon {
            width: 44px; height: 44px;
            background: rgba(255,255,255,0.08);
            border-radius: 12px;
            display: flex; align-items: center; justify-content: center;
            font-size: 22px;
            border: 1px solid rgba(255,255,255,0.1);
        }
        .form-page-header h2 { font-size: 18px; font-weight: 700; margin: 0 0 2px; }
        .form-page-header p  { font-size: 12px; color: rgba(255,255,255,0.45); margin: 0; }
        .tip-box {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-left: 3px solid #f0a500;
            border-radius: 10px;
            padding: 13px 16px;
            font-size: 13px;
            color: #4a5568;
        }
        .tip-box a { color: #0d1b2a; font-weight: 700; }
    </style>
</head>
<body>



<div class="form-container">

    <% if (request.getParameter("error") != null) { %>
    <div class="alert alert-error">❌ <%= request.getParameter("error") %></div>
    <% } %>
    <% if (request.getParameter("success") != null) { %>
    <div class="alert alert-success">✅ <%= request.getParameter("success") %></div>
    <% } %>

    <form id="addCustomerForm" action="AddCustomerServlet" method="post"
          onsubmit="return validateForm()">

        <fieldset>
            <legend>Customer Details</legend>
            <div class="form-grid">

                <div class="form-group">
                    <label for="name">Full Name <span style="color:#ff4757;">*</span></label>
                    <input type="text" id="name" name="name"
                           placeholder="Enter customer's full name" required maxlength="100">
                </div>

                <div class="form-group">
                    <label for="phone">Phone Number <span style="color:#ff4757;">*</span></label>
                    <input type="text" id="phone" name="phone"
                           placeholder="10-digit mobile number" required maxlength="10"
                           oninput="this.value=this.value.replace(/\D/g,'')">
                </div>

                <div class="form-group full-width">
                    <label for="address">Address <span style="color:#ff4757;">*</span></label>
                    <textarea id="address" name="address"
                              placeholder="Street, area, city…"
                              required maxlength="255" rows="3"
                              style="resize:vertical;"></textarea>
                </div>

                <div class="form-group full-width">
                    <label for="credit">Opening Credit Balance (₹) <span style="color:#ff4757;">*</span></label>
                    <input type="number" id="credit" name="credit"
                           placeholder="0.00" step="0.01" min="0" required>
                </div>

            </div>
        </fieldset>

        <div class="form-buttons">
            <button type="submit" class="btn-save">💾 Save Customer</button>
            <button type="reset" class="btn-clear">🔄 Clear</button>
        </div>

    </form>

    <div style="margin-top:20px;">
        <div class="tip-box">
            💡 After saving, manage the customer's credit from the
            <a href="view_customers.jsp">View Customers</a> page.
        </div>
    </div>

</div>

<script>
function validateForm() {
    var name    = document.getElementById('name').value.trim();
    var phone   = document.getElementById('phone').value.trim();
    var address = document.getElementById('address').value.trim();
    var cred    = document.getElementById('credit').value;
    if (!name)               { alert('Please enter customer name.');          return false; }
    if (phone.length !== 10) { alert('Phone must be exactly 10 digits.');     return false; }
    if (!address)            { alert('Please enter customer address.');       return false; }
    if (!cred || parseFloat(cred) < 0) { alert('Please enter a valid credit amount.'); return false; }
    return true;
}
</script>
</body>
</html>
