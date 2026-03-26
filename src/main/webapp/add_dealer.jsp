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
    <title>Add Dealer</title>
    <link rel="stylesheet" href="css/content.css">
</head>
<body>

<div class="form-container">

    <% if (request.getParameter("error") != null) { %>
    <div class="alert alert-error">❌ <%= request.getParameter("error") %></div>
    <% } %>
    <% if (request.getParameter("success") != null) { %>
    <div class="alert alert-success">✅ <%= request.getParameter("success") %></div>
    <% } %>

    <form id="addDealerForm" action="AddDealerServlet" method="post"
          onsubmit="return validateForm()">

        <fieldset>
            <legend data-i18n="dealer.legend">Dealer Information</legend>

            <div class="form-grid">

                <div class="form-group">
                    <label for="name">
                        <span data-i18n="dealer.name">Dealer / Company Name</span>
                        <span style="color:#e53935;">*</span>
                    </label>
                    <input type="text" id="name" name="name"
                           data-i18n-ph="dealer.name_ph"
                           placeholder="Enter dealer or company name"
                           required maxlength="100">
                </div>

                <div class="form-group">
                    <label for="marathiName">
                        <span data-i18n="dealer.marathi_name">Name in Marathi (Optional)</span>
                    </label>
                    <input type="text" id="marathiName" name="marathiName"
                           data-i18n-ph="dealer.marathi_name_ph"
                           placeholder="मराठीत नाव टाका"
                           maxlength="200">
                </div>

                <div class="form-group">
                    <label for="phone">
                        <span data-i18n="dealer.phone">Phone Number</span>
                        <span style="color:#e53935;">*</span>
                    </label>
                    <input type="text" id="phone" name="phone"
                           data-i18n-ph="dealer.phone_ph"
                           placeholder="10-digit mobile number"
                           required maxlength="10"
                           oninput="this.value=this.value.replace(/\D/g,'')">
                </div>

                <div class="form-group full-width">
                    <label for="address">
                        <span data-i18n="dealer.address">Address</span>
                        <span style="color:#e53935;">*</span>
                    </label>
                    <textarea id="address" name="address"
                              data-i18n-ph="dealer.address_ph"
                              placeholder="Enter full address (street, area, city...)"
                              required maxlength="255" rows="3"
                              style="resize:vertical;"></textarea>
                </div>

                <div class="form-group full-width">
                    <label for="credit">
                        <span data-i18n="dealer.credit">Initial Credit Amount (₹)</span>
                        <span style="color:#e53935;">*</span>
                    </label>
                    <input type="number" id="credit" name="credit"
                           placeholder="0.00" step="0.01" min="0" required>
                </div>

            </div>
        </fieldset>

        <div class="form-buttons">
            <button type="submit" class="btn-save" data-i18n="dealer.save">💾 Save Dealer</button>
            <button type="reset"  class="btn-clear" data-i18n="dealer.clear">🔄 Clear</button>
        </div>

    </form>

    <div style="margin-top:24px; background:#fff; border-radius:12px; padding:18px 22px;
                box-shadow:0 2px 8px rgba(0,0,0,0.07); border-left:4px solid #f5a623;">
        <p style="font-size:13px; color:#555; margin:0;">
            💡 <strong>Tip:</strong> After saving, manage the dealer's credit from the
            <a href="view_dealers.jsp" style="color:#2b0d73; font-weight:600;">View Dealers</a> page.
        </p>
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
        alert(lang === 'mr' ? '⚠️ कृपया डीलरचे नाव टाका.' : '⚠️ Please enter dealer name.');
        return false;
    }
    if (phone.length !== 10) {
        alert(lang === 'mr' ? '⚠️ दूरध्वनी क्रमांक १०-अंकी असणे आवश्यक आहे.' : '⚠️ Phone must be exactly 10 digits.');
        return false;
    }
    if (!address) {
        alert(lang === 'mr' ? '⚠️ कृपया पत्ता टाका.' : '⚠️ Please enter dealer address.');
        return false;
    }
    if (!cred || parseFloat(cred) < 0) {
        alert(lang === 'mr' ? '⚠️ कृपया योग्य उधार रक्कम टाका.' : '⚠️ Please enter a valid credit amount.');
        return false;
    }
    return true;
}
</script>
</body>
</html>
