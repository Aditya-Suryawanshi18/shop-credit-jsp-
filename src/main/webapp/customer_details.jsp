<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, doa.DBConnection" %>
<%
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=Please login first");
        return;
    }
    String idStr = request.getParameter("id");
    if (idStr == null) {
        response.sendRedirect("view_customers.jsp");
        return;
    }
    int customerId = Integer.parseInt(idStr);

    String custName = "", custPhone = "";
    double custCredit = 0;
    int txnCount = 0;
    double totalAdded = 0, totalSettled = 0;

    try (Connection conn = DBConnection.getConnection()) {
        PreparedStatement ps = conn.prepareStatement("SELECT * FROM customers WHERE id = ?");
        ps.setInt(1, customerId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            custName   = rs.getString("name");
            custPhone  = rs.getString("phone");
            custCredit = rs.getDouble("credit");
        }
        PreparedStatement psTxn = conn.prepareStatement(
            "SELECT COUNT(*), " +
            "SUM(CASE WHEN transaction_type='ADD' THEN amount ELSE 0 END), " +
            "SUM(CASE WHEN transaction_type='SETTLE' THEN amount ELSE 0 END) " +
            "FROM customer_transactions WHERE customer_id = ?");
        psTxn.setInt(1, customerId);
        ResultSet rsTxn = psTxn.executeQuery();
        if (rsTxn.next()) {
            txnCount     = rsTxn.getInt(1);
            totalAdded   = rsTxn.getDouble(2);
            totalSettled = rsTxn.getDouble(3);
        }
    } catch (Exception e) { /* ignore */ }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Customer Details</title>
    <link rel="stylesheet" href="css/content.css">
    <style>
        .product-tag {
            background: #e8f0fe;
            color: #1a56db;
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            white-space: nowrap;
        }
        .product-tag.settle {
            background: #fef3e2;
            color: #b45309;
        }
        /* Quantity pill */
        .qty-pill {
            display: inline-block;
            background: #f0f4ff;
            color: #2b0d73;
            border: 1px solid #c8d8f8;
            border-radius: 20px;
            padding: 2px 12px;
            font-size: 12px;
            font-weight: 700;
        }
        .qty-pill.settle {
            background: #fef3e2;
            color: #92400e;
            border-color: #fde68a;
        }
        .qty-pill.na {
            background: #f5f5f5;
            color: #aaa;
            border-color: #e0e0e0;
            font-weight: 400;
        }
        /* Payment mode badges */
        .pay-cash {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            background: #e8f5e9;
            color: #1b5e20;
            border: 1px solid #a5d6a7;
            border-radius: 20px;
            padding: 3px 12px;
            font-size: 12px;
            font-weight: 700;
        }
        .pay-online {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            background: #e3f2fd;
            color: #0d47a1;
            border: 1px solid #90caf9;
            border-radius: 20px;
            padding: 3px 12px;
            font-size: 12px;
            font-weight: 700;
        }
        .pay-na {
            display: inline-block;
            background: #f5f5f5;
            color: #aaa;
            border: 1px solid #e0e0e0;
            border-radius: 20px;
            padding: 3px 12px;
            font-size: 12px;
        }
    </style>
</head>
<body>

<div class="content-wrapper">

    <a href="view_customers.jsp" class="back-link">← Back to Customer List</a>

    <!-- Customer Info Card -->
    <div class="detail-info-card">
        <div class="info-item">
            <span class="info-label">Customer ID</span>
            <span class="info-value">#<%= customerId %></span>
        </div>
        <div class="info-item">
            <span class="info-label">Name</span>
            <span class="info-value">👤 <%= custName %></span>
        </div>
        <div class="info-item">
            <span class="info-label">Phone</span>
            <span class="info-value">📞 <%= custPhone %></span>
        </div>
        <div class="info-item">
            <span class="info-label">Current Credit</span>
            <span class="info-value credit-amount">₹ <%= String.format("%.2f", custCredit) %></span>
        </div>
    </div>

    <!-- Stats Row -->
    <div class="stats-row">
        <div class="stat-chip">
            <div class="s-label">Total Transactions</div>
            <div class="s-value"><%= txnCount %></div>
        </div>
        <div class="stat-chip green">
            <div class="s-label">Total Added</div>
            <div class="s-value">₹ <%= String.format("%.2f", totalAdded) %></div>
        </div>
        <div class="stat-chip red">
            <div class="s-label">Total Settled</div>
            <div class="s-value">₹ <%= String.format("%.2f", totalSettled) %></div>
        </div>
        <div class="stat-chip">
            <div class="s-label">Net Credit</div>
            <div class="s-value" style="color:#2b0d73;">₹ <%= String.format("%.2f", custCredit) %></div>
        </div>
    </div>

    <!-- Transaction History Table -->
    <h3 style="font-size:16px; color:#373279; font-weight:700; margin-bottom:12px;
               border-bottom:2px solid #c8b7f6; padding-bottom:8px;">
        📊 Transaction History
    </h3>

    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th>#</th>
                    <th>Txn ID</th>
                    <th>Date</th>
                    <th>Type</th>
                    <th>Product / Item</th>
                    <th>Quantity</th>
                    <th>Payment Mode</th>
                    <th>Amount (₹)</th>
                </tr>
            </thead>
            <tbody>
            <%
                int sNo = 1;
                try (Connection conn = DBConnection.getConnection()) {
                    PreparedStatement ps = conn.prepareStatement(
                        "SELECT * FROM customer_transactions " +
                        "WHERE customer_id = ? ORDER BY transaction_date DESC");
                    ps.setInt(1, customerId);
                    ResultSet rs = ps.executeQuery();
                    boolean hasTxn = false;

                    while (rs.next()) {
                        hasTxn = true;
                        String type        = rs.getString("transaction_type");
                        String prodName    = rs.getString("product_name");
                        int    qty         = rs.getInt("quantity");
                        String paymentMode = rs.getString("payment_mode"); // may be null for old ADD rows
                        if (prodName == null || prodName.trim().isEmpty()) prodName = "—";
                        boolean isAdd = "ADD".equals(type);
            %>
                <tr>
                    <td><%= sNo++ %></td>
                    <td><strong><%= rs.getInt("id") %></strong></td>
                    <td><%= rs.getDate("transaction_date") %></td>
                    <td>
                        <% if (isAdd) { %>
                        <span class="badge-add">➕ ADD</span>
                        <% } else { %>
                        <span class="badge-settle">✅ SETTLE</span>
                        <% } %>
                    </td>
                    <td>
                        <span class="product-tag <%= isAdd ? "" : "settle" %>">
                            📦 <%= prodName %>
                        </span>
                    </td>
                    <td>
                        <% if (isAdd && qty > 0) { %>
                        <span class="qty-pill"><%= qty %> unit<%= qty != 1 ? "s" : "" %></span>
                        <% } else if (!isAdd) { %>
                        <span class="qty-pill settle">—</span>
                        <% } else { %>
                        <span class="qty-pill na">—</span>
                        <% } %>
                    </td>
                    <td>
                        <%
                            if (!isAdd && paymentMode != null) {
                                if ("CASH".equals(paymentMode)) {
                        %>
                        <span class="pay-cash">💵 Cash</span>
                        <%          } else if ("ONLINE".equals(paymentMode)) { %>
                        <span class="pay-online">📱 Online</span>
                        <%          } else { %>
                        <span class="pay-na"><%= paymentMode %></span>
                        <%          }
                            } else { %>
                        <span class="pay-na">—</span>
                        <%  } %>
                    </td>
                    <td style="font-weight:700; color:<%= isAdd ? "#2e7d32" : "#c62828" %>;">
                        ₹ <%= String.format("%.2f", rs.getDouble("amount")) %>
                    </td>
                </tr>
            <%
                    }
                    if (!hasTxn) {
            %>
                <tr>
                    <td colspan="8" class="no-data">No transactions found for this customer.</td>
                </tr>
            <%
                    }
                } catch (Exception e) {
            %>
                <tr>
                    <td colspan="8" class="no-data">❌ Error: <%= e.getMessage() %></td>
                </tr>
            <%
                }
            %>
            </tbody>
        </table>
    </div>
</div>

</body>
</html>
