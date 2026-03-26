<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, doa.DBConnection" %>
<%
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=Please login first");
        return;
    }
    String fullName = (String) session.getAttribute("fullName");
    if (fullName == null) fullName = (String) session.getAttribute("admin");

    int totalCustomers = 0, totalDealers = 0, totalProducts = 0;
    double totalCustomerCredit = 0, totalDealerCredit = 0;

    try (Connection conn = DBConnection.getConnection()) {
        ResultSet r1 = conn.createStatement().executeQuery("SELECT COUNT(*) FROM customers");
        if (r1.next()) totalCustomers = r1.getInt(1);
        ResultSet r2 = conn.createStatement().executeQuery("SELECT NVL(SUM(credit),0) FROM customers");
        if (r2.next()) totalCustomerCredit = r2.getDouble(1);
        ResultSet r3 = conn.createStatement().executeQuery("SELECT COUNT(*) FROM dealers");
        if (r3.next()) totalDealers = r3.getInt(1);
        ResultSet r4 = conn.createStatement().executeQuery("SELECT NVL(SUM(credit),0) FROM dealers");
        if (r4.next()) totalDealerCredit = r4.getDouble(1);
        ResultSet r5 = conn.createStatement().executeQuery("SELECT COUNT(*) FROM products");
        if (r5.next()) totalProducts = r5.getInt(1);
    } catch (Exception e) { /* ignore */ }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Dashboard</title>
    <link rel="stylesheet" href="css/content.css">
    <style>
        body { padding: 0; background: #f0f2f8; }
        .overview-row {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 16px;
            padding: 24px 26px 0;
        }
        .ov-chip {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 14px;
            padding: 18px 16px;
            box-shadow: 0 1px 4px rgba(0,0,0,0.06);
            text-align: center;
            position: relative;
            overflow: hidden;
        }
        .ov-chip::before {
            content: ''; position: absolute;
            top: 0; left: 0; right: 0; height: 3px;
            border-radius: 14px 14px 0 0;
        }
        .ov-chip.c1::before { background: linear-gradient(90deg, #2563eb, #60a5fa); }
        .ov-chip.c2::before { background: linear-gradient(90deg, #059669, #34d399); }
        .ov-chip.c3::before { background: linear-gradient(90deg, #c2730a, #f0a500); }
        .ov-chip.c4::before { background: linear-gradient(90deg, #b91c1c, #f87171); }
        .ov-chip.c5::before { background: linear-gradient(90deg, #6d28d9, #a78bfa); }
        .ov-chip .ov-icon { font-size: 24px; margin-bottom: 8px; }
        .ov-chip .ov-val  { font-size: 22px; font-weight: 800; color: #0d1b2a; font-variant-numeric: tabular-nums; }
        .ov-chip .ov-val.money { font-size: 17px; }
        .ov-chip .ov-label { font-size: 11px; font-weight: 600; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.8px; margin-top: 4px; }
        @media (max-width: 1100px) { .overview-row { grid-template-columns: repeat(3,1fr); } }
        @media (max-width: 640px)  { .overview-row { grid-template-columns: 1fr 1fr; } }
    </style>
</head>
<body>

<!-- Overview chips -->
<div class="overview-row">
    <div class="ov-chip c1">
        <div class="ov-icon">👥</div>
        <div class="ov-val"><%= totalCustomers %></div>
        <div class="ov-label" data-i18n="dash.total_customers">Customers</div>
    </div>
    <div class="ov-chip c2">
        <div class="ov-icon">💰</div>
        <div class="ov-val money">₹ <%= String.format("%,.0f", totalCustomerCredit) %></div>
        <div class="ov-label" data-i18n="dash.customer_credit">Customer Credit</div>
    </div>
    <div class="ov-chip c3">
        <div class="ov-icon">🏬</div>
        <div class="ov-val"><%= totalDealers %></div>
        <div class="ov-label" data-i18n="dash.total_dealers">Dealers</div>
    </div>
    <div class="ov-chip c4">
        <div class="ov-icon">💳</div>
        <div class="ov-val money">₹ <%= String.format("%,.0f", totalDealerCredit) %></div>
        <div class="ov-label" data-i18n="dash.dealer_credit">Dealer Credit</div>
    </div>
    <div class="ov-chip c5">
        <div class="ov-icon">📦</div>
        <div class="ov-val"><%= totalProducts %></div>
        <div class="ov-label" data-i18n="dash.total_products">Products</div>
    </div>
</div>

<!-- Quick Actions -->
<div class="section-label" data-i18n="dash.quick_actions">Quick Actions</div>

<div class="cards-grid" style="padding-top:8px;">

    <div class="dash-card card-blue" onclick="parent.loadPage('add_customer.jsp','Add Customer',null)">
        <div class="card-icon">➕</div>
        <div>
            <h3 data-i18n="dash.add_customer">Add Customer</h3>
            <p data-i18n="dash.add_customer_desc">Register a new customer with credit account</p>
        </div>
    </div>

    <div class="dash-card card-green" onclick="parent.loadPage('view_customers.jsp','Customers',null)">
        <div class="card-icon">👥</div>
        <div>
            <h3 data-i18n="dash.customers">Customers</h3>
            <p data-i18n="dash.customers_desc">Manage credit &amp; transactions</p>
        </div>
    </div>

    <div class="dash-card card-orange" onclick="parent.loadPage('add_dealer.jsp','Add Dealer',null)">
        <div class="card-icon">🏬</div>
        <div>
            <h3 data-i18n="dash.add_dealer">Add Dealer</h3>
            <p data-i18n="dash.add_dealer_desc">Register a new dealer supplier</p>
        </div>
    </div>

    <div class="dash-card card-purple" onclick="parent.loadPage('view_dealers.jsp','Dealers',null)">
        <div class="card-icon">📋</div>
        <div>
            <h3 data-i18n="dash.dealers">Dealers</h3>
            <p data-i18n="dash.dealers_desc">Manage dealer credit &amp; stock</p>
        </div>
    </div>

    <div class="dash-card card-teal" onclick="parent.loadPage('view_products.jsp','Products',null)">
        <div class="card-icon">📦</div>
        <div>
            <h3 data-i18n="dash.products">Products</h3>
            <p data-i18n="dash.products_desc">View &amp; manage stock inventory</p>
        </div>
    </div>

</div>

<script src="js/i18n.js"></script>
</body>
</html>
