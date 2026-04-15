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

    // ── Monthly customer transaction amounts (last 12 months) ──
    double[] monthlyCustomerAdded   = new double[12];
    double[] monthlyCustomerSettled = new double[12];
    double[] monthlyDealerAdded     = new double[12];
    int[]    monthlyCashSaleCount   = new int[12];
    String[] monthLabels            = new String[12];

    // ── Summary stats ──
    double totalAllAdded   = 0;
    double totalAllSettled = 0;
    int    totalTxnCount   = 0;
    double peakMonthVal    = 0;
    double lowestMonthVal  = Double.MAX_VALUE;
    double currentMonthVal = 0;

    try (Connection conn = DBConnection.getConnection()) {
        // Overview counts
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

        // ── Build month labels for last 12 months (oldest → newest) ──
        java.util.Calendar cal = java.util.Calendar.getInstance();
        for (int i = 11; i >= 0; i--) {
            java.util.Calendar mc = (java.util.Calendar) cal.clone();
            mc.add(java.util.Calendar.MONTH, -i);
            int idx = 11 - i;
            monthLabels[idx] = new java.text.SimpleDateFormat("MMM yy").format(mc.getTime());
        }

        // ── Customer ADD transactions per month ──
        String sqlCustAdd =
            "SELECT TO_CHAR(transaction_date,'YYYY-MM') AS ym, NVL(SUM(amount),0) AS total " +
            "FROM customer_transactions " +
            "WHERE transaction_type = 'ADD' " +
            "  AND transaction_date >= ADD_MONTHS(TRUNC(SYSDATE,'MM'), -11) " +
            "GROUP BY TO_CHAR(transaction_date,'YYYY-MM') " +
            "ORDER BY ym ASC";
        ResultSet rCA = conn.createStatement().executeQuery(sqlCustAdd);
        while (rCA.next()) {
            String ym  = rCA.getString("ym");
            double amt = rCA.getDouble("total");
            int idx = getMonthIndex(ym, cal);
            if (idx >= 0 && idx < 12) monthlyCustomerAdded[idx] = amt;
        }

        // ── Customer SETTLE transactions per month ──
        String sqlCustSettle =
            "SELECT TO_CHAR(transaction_date,'YYYY-MM') AS ym, NVL(SUM(amount),0) AS total " +
            "FROM customer_transactions " +
            "WHERE transaction_type = 'SETTLE' " +
            "  AND transaction_date >= ADD_MONTHS(TRUNC(SYSDATE,'MM'), -11) " +
            "GROUP BY TO_CHAR(transaction_date,'YYYY-MM') " +
            "ORDER BY ym ASC";
        ResultSet rCS = conn.createStatement().executeQuery(sqlCustSettle);
        while (rCS.next()) {
            String ym  = rCS.getString("ym");
            double amt = rCS.getDouble("total");
            int idx = getMonthIndex(ym, cal);
            if (idx >= 0 && idx < 12) monthlyCustomerSettled[idx] = amt;
        }

        // ── Dealer ADD (stock purchase) per month ──
        String sqlDlrAdd =
            "SELECT TO_CHAR(transaction_date,'YYYY-MM') AS ym, NVL(SUM(amount),0) AS total " +
            "FROM dealer_transactions " +
            "WHERE transaction_type = 'ADD' " +
            "  AND transaction_date >= ADD_MONTHS(TRUNC(SYSDATE,'MM'), -11) " +
            "GROUP BY TO_CHAR(transaction_date,'YYYY-MM') " +
            "ORDER BY ym ASC";
        ResultSet rDA = conn.createStatement().executeQuery(sqlDlrAdd);
        while (rDA.next()) {
            String ym  = rDA.getString("ym");
            double amt = rDA.getDouble("total");
            int idx = getMonthIndex(ym, cal);
            if (idx >= 0 && idx < 12) monthlyDealerAdded[idx] = amt;
        }

        // ── Cash sale count per month ──
        String sqlCash =
            "SELECT TO_CHAR(transaction_date,'YYYY-MM') AS ym, COUNT(*) AS cnt " +
            "FROM customer_transactions " +
            "WHERE transaction_type = 'CASH_SALE' " +
            "  AND transaction_date >= ADD_MONTHS(TRUNC(SYSDATE,'MM'), -11) " +
            "GROUP BY TO_CHAR(transaction_date,'YYYY-MM') " +
            "ORDER BY ym ASC";
        ResultSet rCash = conn.createStatement().executeQuery(sqlCash);
        while (rCash.next()) {
            String ym  = rCash.getString("ym");
            int    cnt = rCash.getInt("cnt");
            int idx = getMonthIndex(ym, cal);
            if (idx >= 0 && idx < 12) monthlyCashSaleCount[idx] = cnt;
        }

        // ── Overall summary stats ──
        ResultSet rSum = conn.createStatement().executeQuery(
            "SELECT NVL(SUM(CASE WHEN transaction_type='ADD' THEN amount ELSE 0 END),0) AS added, " +
            "       NVL(SUM(CASE WHEN transaction_type='SETTLE' THEN amount ELSE 0 END),0) AS settled, " +
            "       COUNT(*) AS cnt " +
            "FROM customer_transactions");
        if (rSum.next()) {
            totalAllAdded   = rSum.getDouble("added");
            totalAllSettled = rSum.getDouble("settled");
            totalTxnCount   = rSum.getInt("cnt");
        }

        // Peak, lowest, current month for customer credit added
        for (int i = 0; i < 12; i++) {
            double v = monthlyCustomerAdded[i];
            if (v > peakMonthVal) peakMonthVal = v;
            if (v > 0 && v < lowestMonthVal) lowestMonthVal = v;
        }
        currentMonthVal = monthlyCustomerAdded[11];
        if (lowestMonthVal == Double.MAX_VALUE) lowestMonthVal = 0;

    } catch (Exception e) { e.printStackTrace(); }

    // ── Helper: compute index (0-11, 0=oldest) from "YYYY-MM" ──
    // Defined as a method below
%>
<%!
private int getMonthIndex(String ym, java.util.Calendar now) {
    try {
        java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM");
        java.util.Date d = sdf.parse(ym);
        java.util.Calendar c = java.util.Calendar.getInstance();
        c.setTime(d);
        int nowY = now.get(java.util.Calendar.YEAR);
        int nowM = now.get(java.util.Calendar.MONTH);
        int cY   = c.get(java.util.Calendar.YEAR);
        int cM   = c.get(java.util.Calendar.MONTH);
        int diff = (nowY - cY) * 12 + (nowM - cM); // 0 = current, 11 = oldest
        int idx  = 11 - diff;                        // 0 = oldest, 11 = current
        return idx;
    } catch (Exception e) { return -1; }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Dashboard</title>
    <link rel="stylesheet" href="css/content.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script>
    <style>
        body { padding: 0; background: #f0f2f8; }

        /* ═══ OVERVIEW CHIPS ═══ */
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

        /* ═══ CHART SECTION ═══ */
        .charts-section { padding: 24px 26px; display: flex; flex-direction: column; gap: 20px; }

        .chart-row { display: grid; grid-template-columns: 2fr 1fr; gap: 20px; }
        @media (max-width: 1024px) { .chart-row { grid-template-columns: 1fr; } }

        .chart-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 16px;
            padding: 22px 24px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
        }
        .chart-card-header {
            display: flex; align-items: flex-start;
            justify-content: space-between;
            margin-bottom: 18px; gap: 12px; flex-wrap: wrap;
        }
        .chart-card-header h3 { font-size: 15px; font-weight: 800; color: #0d1b2a; margin: 0 0 3px; }
        .chart-card-header p  { font-size: 12px; color: #94a3b8; margin: 0; }
        .chart-badge {
            padding: 5px 14px; border-radius: 20px;
            font-size: 11px; font-weight: 700; white-space: nowrap;
        }
        .badge-blue   { background: rgba(37,99,235,0.10); color: #2563eb; }
        .badge-green  { background: rgba(5,150,105,0.10); color: #059669; }
        .badge-orange { background: rgba(194,115,10,0.10); color: #c2730a; }

        .canvas-wrap {
            position: relative; border-radius: 10px;
            background: linear-gradient(135deg, #f8fafc, #f0f2f8);
            padding: 12px; border: 1px solid rgba(13,27,42,0.04);
        }
        .canvas-wrap.sm { height: 220px; }
        .canvas-wrap.lg { height: 280px; }

        /* Stats sidebar */
        .stats-sidebar {
            display: flex; flex-direction: column; gap: 10px;
        }
        .stat-block {
            background: #fff; border: 1px solid #e2e8f0; border-radius: 12px;
            padding: 14px 16px; display: flex; align-items: center;
            justify-content: space-between; gap: 10px;
            box-shadow: 0 1px 4px rgba(0,0,0,0.05);
            transition: box-shadow 0.2s;
        }
        .stat-block:hover { box-shadow: 0 4px 14px rgba(0,0,0,0.10); }
        .stat-block .sb-icon { font-size: 22px; flex-shrink: 0; }
        .stat-block .sb-info { flex: 1; }
        .stat-block .sb-label { font-size: 11px; font-weight: 600; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.6px; }
        .stat-block .sb-val   { font-size: 16px; font-weight: 800; color: #0d1b2a; font-variant-numeric: tabular-nums; }
        .stat-block .sb-val.green  { color: #059669; }
        .stat-block .sb-val.orange { color: #c2730a; }
        .stat-block .sb-val.red    { color: #b91c1c; }
        .stat-block .sb-val.blue   { color: #2563eb; }
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

<div class="charts-section">

    <!-- ROW 1: Credit trend + stats sidebar -->
    <div class="chart-row">

        <!-- Main trend chart -->
        <div class="chart-card">
            <div class="chart-card-header">
                <div>
                    <h3>📊 Monthly Credit Activity (Last 12 Months)</h3>
                    <p>Customer credit added vs. settlements — live from database</p>
                </div>
                <span class="chart-badge badge-blue">CREDIT TREND</span>
            </div>
            <div class="canvas-wrap lg">
                <canvas id="creditTrendChart"></canvas>
            </div>
        </div>

        <!-- Stats sidebar -->
        <div class="stats-sidebar">
            <div class="stat-block">
                <span class="sb-icon">💰</span>
                <div class="sb-info">
                    <div class="sb-label">Total Credit Added</div>
                    <div class="sb-val green">₹ <%= String.format("%,.0f", totalAllAdded) %></div>
                </div>
            </div>
            <div class="stat-block">
                <span class="sb-icon">✅</span>
                <div class="sb-info">
                    <div class="sb-label">Total Settled</div>
                    <div class="sb-val red">₹ <%= String.format("%,.0f", totalAllSettled) %></div>
                </div>
            </div>
            <div class="stat-block">
                <span class="sb-icon">📈</span>
                <div class="sb-info">
                    <div class="sb-label">Peak Month (Added)</div>
                    <div class="sb-val orange">₹ <%= String.format("%,.0f", peakMonthVal) %></div>
                </div>
            </div>
            <div class="stat-block">
                <span class="sb-icon">📅</span>
                <div class="sb-info">
                    <div class="sb-label">This Month (Added)</div>
                    <div class="sb-val blue">₹ <%= String.format("%,.0f", currentMonthVal) %></div>
                </div>
            </div>
            <div class="stat-block">
                <span class="sb-icon">🔄</span>
                <div class="sb-info">
                    <div class="sb-label">Total Transactions</div>
                    <div class="sb-val"><%= totalTxnCount %></div>
                </div>
            </div>
            <div class="stat-block">
                <span class="sb-icon">💹</span>
                <div class="sb-info">
                    <div class="sb-label">Net Outstanding</div>
                    <div class="sb-val green">₹ <%= String.format("%,.0f", totalCustomerCredit) %></div>
                </div>
            </div>
        </div>
    </div>

    <!-- ROW 2: Dealer purchases + Cash sales -->
    <div class="chart-row">

        <div class="chart-card">
            <div class="chart-card-header">
                <div>
                    <h3>🏬 Dealer Stock Purchases (Last 12 Months)</h3>
                    <p>Monthly value of goods received from dealers</p>
                </div>
                <span class="chart-badge badge-orange">DEALER ACTIVITY</span>
            </div>
            <div class="canvas-wrap sm">
                <canvas id="dealerChart"></canvas>
            </div>
        </div>

        <div class="chart-card">
            <div class="chart-card-header">
                <div>
                    <h3>💵 Cash Sale Count</h3>
                    <p>Monthly cash & online sale transactions</p>
                </div>
                <span class="chart-badge badge-green">CASH SALES</span>
            </div>
            <div class="canvas-wrap sm">
                <canvas id="cashSaleChart"></canvas>
            </div>
        </div>
    </div>

</div>

<script src="js/i18n.js"></script>
<script>
// ── Data from Java ─────────────────────────────────────────────────────────
var months  = <%= java.util.Arrays.toString(monthLabels)
                    .replace("[","[\"").replace("]","\"]").replace(", ","\",\"") %>;

var custAdded   = <%= java.util.Arrays.toString(monthlyCustomerAdded) %>;
var custSettled = <%= java.util.Arrays.toString(monthlyCustomerSettled) %>;
var dlrAdded    = <%= java.util.Arrays.toString(monthlyDealerAdded) %>;
var cashCounts  = <%= java.util.Arrays.toString(monthlyCashSaleCount) %>;

// ── Chart defaults ─────────────────────────────────────────────────────────
Chart.defaults.font.family = "'Outfit', sans-serif";

function makeGrad(ctx, color1, color2) {
    var g = ctx.createLinearGradient(0, 0, 0, 300);
    g.addColorStop(0, color1);
    g.addColorStop(1, color2);
    return g;
}

var tickStyle = { font: { size: 11, weight: '600' }, color: '#94a3b8' };
var gridStyle = { color: 'rgba(13,27,42,0.05)', drawBorder: false };

// ── 1. Credit Trend (Line) ─────────────────────────────────────────────────
(function() {
    var ctx = document.getElementById('creditTrendChart').getContext('2d');
    var gAdd = makeGrad(ctx, 'rgba(5,150,105,0.22)', 'rgba(5,150,105,0.02)');
    var gSet = makeGrad(ctx, 'rgba(185,28,28,0.18)', 'rgba(185,28,28,0.02)');
    new Chart(ctx, {
        type: 'line',
        data: {
            labels: months,
            datasets: [
                {
                    label: 'Credit Added (₹)',
                    data: custAdded,
                    borderColor: '#059669',
                    backgroundColor: gAdd,
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 5,
                    pointBackgroundColor: '#fff',
                    pointBorderColor: '#059669',
                    pointBorderWidth: 2,
                    pointHoverRadius: 7,
                    yAxisID: 'y',
                },
                {
                    label: 'Settled (₹)',
                    data: custSettled,
                    borderColor: '#b91c1c',
                    backgroundColor: gSet,
                    borderWidth: 2.5,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 4,
                    pointBackgroundColor: '#fff',
                    pointBorderColor: '#b91c1c',
                    pointBorderWidth: 1.5,
                    pointHoverRadius: 6,
                    yAxisID: 'y',
                }
            ]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            interaction: { mode: 'index', intersect: false },
            plugins: {
                legend: {
                    display: true, position: 'top',
                    labels: { usePointStyle: true, padding: 16, boxPadding: 6,
                              font: { size: 12, weight: '700' }, color: '#4a5568' }
                },
                tooltip: {
                    backgroundColor: 'rgba(13,27,42,0.88)',
                    padding: 12, titleFont: { size: 13, weight: '700' },
                    bodyFont: { size: 12 }, borderColor: 'rgba(255,255,255,0.1)',
                    borderWidth: 1, usePointStyle: true,
                    callbacks: {
                        label: function(c) {
                            return ' ' + c.dataset.label + ': ₹ ' + c.parsed.y.toLocaleString('en-IN');
                        }
                    }
                }
            },
            scales: {
                y: { ticks: Object.assign({}, tickStyle, {
                         callback: function(v) {
                             return v >= 1000 ? '₹' + (v/1000).toFixed(0) + 'K' : '₹' + v;
                         }
                     }), grid: gridStyle },
                x: { ticks: tickStyle, grid: gridStyle }
            }
        }
    });
})();

// ── 2. Dealer Purchases (Bar) ──────────────────────────────────────────────
(function() {
    var ctx = document.getElementById('dealerChart').getContext('2d');
    var gBar = makeGrad(ctx, '#f0a500', 'rgba(240,165,0,0.35)');
    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: months,
            datasets: [{
                label: 'Stock Purchased (₹)',
                data: dlrAdded,
                backgroundColor: gBar,
                borderColor: '#c2730a',
                borderWidth: 1.5,
                borderRadius: 6,
                borderSkipped: false,
            }]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: 'rgba(13,27,42,0.88)',
                    padding: 10, usePointStyle: true,
                    callbacks: {
                        label: function(c) {
                            return ' ₹ ' + c.parsed.y.toLocaleString('en-IN');
                        }
                    }
                }
            },
            scales: {
                y: { ticks: Object.assign({}, tickStyle, {
                         callback: function(v) {
                             return v >= 1000 ? '₹' + (v/1000).toFixed(0) + 'K' : '₹' + v;
                         }
                     }), grid: gridStyle },
                x: { ticks: Object.assign({}, tickStyle, { maxRotation: 45 }), grid: { display: false } }
            }
        }
    });
})();

// ── 3. Cash Sale Count (Bar) ───────────────────────────────────────────────
(function() {
    var ctx = document.getElementById('cashSaleChart').getContext('2d');
    var gBar = makeGrad(ctx, 'rgba(37,99,235,0.75)', 'rgba(37,99,235,0.25)');
    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: months,
            datasets: [{
                label: 'Cash Sales',
                data: cashCounts,
                backgroundColor: gBar,
                borderColor: '#1d4ed8',
                borderWidth: 1.5,
                borderRadius: 6,
                borderSkipped: false,
            }]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: 'rgba(13,27,42,0.88)',
                    padding: 10,
                    callbacks: {
                        label: function(c) { return ' ' + c.parsed.y + ' transactions'; }
                    }
                }
            },
            scales: {
                y: {
                    ticks: Object.assign({}, tickStyle, { stepSize: 1 }),
                    grid: gridStyle,
                    beginAtZero: true
                },
                x: { ticks: Object.assign({}, tickStyle, { maxRotation: 45 }), grid: { display: false } }
            }
        }
    });
})();
</script>
</body>
</html>
