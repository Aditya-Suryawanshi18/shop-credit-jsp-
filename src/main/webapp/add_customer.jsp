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
        .tip-box {
            background: #fff; border: 1px solid #e2e8f0;
            border-left: 3px solid #f0a500; border-radius: 10px;
            padding: 13px 16px; font-size: 13px; color: #4a5568;
            margin-top: 20px;
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
            <legend data-i18n="cust.legend">Customer Details</legend>
            <div class="form-grid">

                <div class="form-group">
                    <label for="name">
                        <span data-i18n="cust.name">Full Name</span>
                        <span style="color:#ff4757;">*</span>
                    </label>
                    <input type="text" id="name" name="name"
                           data-i18n-ph="cust.name_ph"
                           placeholder="Enter customer's full name"
                           required maxlength="100">
                </div>

                <div class="form-group">
                    <label for="marathiName">
                        <span data-i18n="cust.marathi_name">Name in Marathi (Optional)</span>
                    </label>
                    <input type="text" id="marathiName" name="marathiName"
                           data-i18n-ph="cust.marathi_name_ph"
                           placeholder="मराठीत नाव टाका"
                           maxlength="200">
                </div>

                <div class="form-group">
                    <label for="phone">
                        <span data-i18n="cust.phone">Phone Number</span>
                        <span style="color:#ff4757;">*</span>
                    </label>
                    <input type="text" id="phone" name="phone"
                           data-i18n-ph="cust.phone_ph"
                           placeholder="10-digit mobile number"
                           required maxlength="10"
                           oninput="this.value=this.value.replace(/\D/g,'')">
                </div>

                <div class="form-group full-width">
                    <label for="address">
                        <span data-i18n="cust.address">Address</span>
                        <span style="color:#ff4757;">*</span>
                    </label>
                    <textarea id="address" name="address"
                              data-i18n-ph="cust.address_ph"
                              placeholder="Street, area, city…"
                              required maxlength="255" rows="3"
                              style="resize:vertical;"></textarea>
                </div>

                <div class="form-group full-width">
                    <label for="credit">
                        <span data-i18n="cust.credit">Opening Credit Balance (₹)</span>
                        <span style="color:#ff4757;">*</span>
                    </label>
                    <input type="number" id="credit" name="credit"
                           placeholder="0.00" step="0.01" min="0" required>
                </div>

            </div>
        </fieldset>

        <div class="form-buttons">
            <button type="submit" class="btn-save" data-i18n="cust.save">💾 Save Customer</button>
            <button type="reset"  class="btn-clear" data-i18n="cust.clear">🔄 Clear</button>
        </div>

    </form>

    <div class="tip-box">
        💡 After saving, manage the customer's credit from the
        <a href="view_customers.jsp">View Customers</a> page.
    </div>

</div>

<script src="js/i18n.js"></script>
<script>
function validateForm() {
    var name    = document.getElementById('name').value.trim();
    var phone   = document.getElementById('phone').value.trim();
    var address = document.getElementById('address').value.trim();
    var cred    = document.getElementById('credit').value;
    var lang    = i18n.getLang();

    if (!name) {
        alert(lang === 'mr' ? 'कृपया ग्राहकाचे नाव टाका.' : 'Please enter customer name.');
        return false;
    }
    if (phone.length !== 10) {
        alert(lang === 'mr' ? 'दूरध्वनी क्रमांक १०-अंकी असणे आवश्यक आहे.' : 'Phone must be exactly 10 digits.');
        return false;
    }
    if (!address) {
        alert(lang === 'mr' ? 'कृपया पत्ता टाका.' : 'Please enter customer address.');
        return false;
    }
    if (!cred || parseFloat(cred) < 0) {
        alert(lang === 'mr' ? 'कृपया योग्य उधार रक्कम टाका.' : 'Please enter a valid credit amount.');
        return false;
    }
    return true;
}
</script>
</body>
</html>
