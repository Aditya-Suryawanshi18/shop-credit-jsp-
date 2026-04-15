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

        /* ═══ GROWTH CHART SECTION ═══ */
        .growth-section { padding: 24px 26px; }
        .growth-container {
            display: grid;
            grid-template-columns: 1fr 280px;
            gap: 20px;
        }
        @media (max-width: 1024px) { .growth-container { grid-template-columns: 1fr; } }

        .chart-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 16px;
            padding: 24px 28px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
            position: relative;
            overflow: hidden;
        }
        .chart-card::before {
            content: '';
            position: absolute;
            top: -40%;
            right: -40%;
            width: 400px;
            height: 400px;
            background: radial-gradient(circle, rgba(13,27,42,0.02) 0%, transparent 70%);
            border-radius: 50%;
            pointer-events: none;
        }
        
        .chart-header {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            margin-bottom: 24px;
            gap: 16px;
            flex-wrap: wrap;
            position: relative;
            z-index: 2;
        }
        .chart-title-group h3 {
            font-size: 18px;
            font-weight: 800;
            color: #0d1b2a;
            margin: 0 0 4px;
            letter-spacing: 0.3px;
        }
        .chart-title-group p {
            font-size: 12px;
            color: #94a3b8;
            margin: 0;
        }
        .chart-badge {
            background: linear-gradient(135deg, #ff6b6b, #ff8787);
            color: #fff;
            padding: 7px 16px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.6px;
            display: flex;
            align-items: center;
            gap: 7px;
            box-shadow: 0 4px 12px rgba(255,107,107,0.25);
            white-space: nowrap;
        }
        .chart-badge .trend-icon {
            font-size: 16px;
            animation: slideDown 0.8s ease-in-out infinite;
        }
        @keyframes slideDown {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(4px); }
        }
        
        .chart-canvas-wrapper {
            position: relative;
            height: 320px;
            margin-bottom: 16px;
            border-radius: 12px;
            background: linear-gradient(135deg, #f8fafc 0%, #f0f2f8 100%);
            padding: 16px;
            border: 1px solid rgba(13,27,42,0.05);
        }

        /* ═══ STATS SIDEBAR ═══ */
        .stats-card {
            background: linear-gradient(135deg, #fff8f0 0%, #fffbf5 100%);
            border: 1px solid #f5dab0;
            border-radius: 14px;
            padding: 20px;
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        .stats-card h4 {
            font-size: 13px;
            font-weight: 700;
            color: #7a3800;
            margin: 0 0 6px;
            text-transform: uppercase;
            letter-spacing: 0.6px;
        }
        .stat-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            padding: 12px;
            background: #fff;
            border-radius: 10px;
            border: 1px solid rgba(244,160,23,0.15);
            transition: all 0.2s;
        }
        .stat-item:hover {
            background: #fff;
            border-color: #f5a623;
            box-shadow: 0 2px 8px rgba(244,160,23,0.12);
        }
        .stat-item-left {
            display: flex;
            align-items: center;
            gap: 10px;
            flex: 1;
        }
        .stat-item-icon {
            font-size: 20px;
            opacity: 0.8;
            flex-shrink: 0;
        }
        .stat-item-label {
            font-size: 12px;
            font-weight: 600;
            color: #7a3800;
            line-height: 1.3;
        }
        .stat-item-value {
            font-size: 16px;
            font-weight: 800;
            color: #d4681a;
            font-variant-numeric: tabular-nums;
            flex-shrink: 0;
        }

        .chart-note {
            font-size: 11px;
            color: #94a3b8;
            text-align: center;
            padding-top: 12px;
            border-top: 1px solid #e2e8f0;
            position: relative;
            z-index: 2;
        }

        /* ═══ QUICK ACTIONS SECTION ═══ */
        .quick-actions-section { padding: 24px 26px; }
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

<!-- Business Growth Section -->
<div class="growth-section">
    <div class="growth-container">
        <!-- Chart -->
        <div class="chart-card">
            <div class="chart-header">
                <div class="chart-title-group">
                    <h3>📊 Monthly Business Trend</h3>
                    <p>Transaction volume & revenue tracking over 12 months</p>
                </div>
                <div class="chart-badge">
                    <span class="trend-icon">📉</span>
                    <span>-18% YoY</span>
                </div>
            </div>
            <div class="chart-canvas-wrapper">
                <canvas id="businessChart"></canvas>
            </div>
        </div>

        <!-- Stats Sidebar -->
        <div class="stats-card">
            <h4>📈 Key Metrics</h4>
            
            <div class="stat-item">
                <div class="stat-item-left">
                    <span class="stat-item-icon">🎯</span>
                    <span class="stat-item-label">Avg Monthly</span>
                </div>
                <span class="stat-item-value">₹18.5K</span>
            </div>

            <div class="stat-item">
                <div class="stat-item-left">
                    <span class="stat-item-icon">📈</span>
                    <span class="stat-item-label">Peak Month</span>
                </div>
                <span class="stat-item-value">₹32K</span>
            </div>

            <div class="stat-item">
                <div class="stat-item-left">
                    <span class="stat-item-icon">📉</span>
                    <span class="stat-item-label">Lowest Month</span>
                </div>
                <span class="stat-item-value">₹8.2K</span>
            </div>

            <div class="stat-item">
                <div class="stat-item-left">
                    <span class="stat-item-icon">💹</span>
                    <span class="stat-item-label">Current Month</span>
                </div>
                <span class="stat-item-value">₹12.5K</span>
            </div>

            <div class="stat-item">
                <div class="stat-item-left">
                    <span class="stat-item-icon">🔄</span>
                    <span class="stat-item-label">Transactions</span>
                </div>
                <span class="stat-item-value">847</span>
            </div>
        </div>
    </div>
</div>



<script src="js/i18n.js"></script>
<script>
// ═══════════════════════════════════════════════════════════
// MONTHLY BUSINESS GROWTH CHART
// Shows downward trend with realistic data
// ═══════════════════════════════════════════════════════════

const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const chartContext = document.getElementById('businessChart');

// Realistic downward trend data (showing declining business)
const revenueData = [32000, 30500, 28900, 26700, 25300, 23800, 21500, 19800, 18200, 15900, 14100, 12500];
const transactionData = [145, 138, 132, 124, 118, 110, 98, 89, 81, 72, 65, 58];

const ctx = chartContext.getContext('2d');

// Create gradient for area
const gradient = ctx.createLinearGradient(0, 0, 0, 300);
gradient.addColorStop(0, 'rgba(255, 107, 107, 0.25)');
gradient.addColorStop(1, 'rgba(255, 107, 107, 0.02)');

const gradient2 = ctx.createLinearGradient(0, 0, 0, 300);
gradient2.addColorStop(0, 'rgba(244, 160, 23, 0.20)');
gradient2.addColorStop(1, 'rgba(244, 160, 23, 0.02)');

new Chart(ctx, {
    type: 'line',
    data: {
        labels: months,
        datasets: [
            {
                label: 'Revenue (₹)',
                data: revenueData,
                borderColor: '#ff6b6b',
                backgroundColor: gradient,
                borderWidth: 3,
                fill: true,
                pointRadius: 5,
                pointBackgroundColor: '#fff',
                pointBorderColor: '#ff6b6b',
                pointBorderWidth: 2,
                pointHoverRadius: 7,
                pointHoverBackgroundColor: '#ff6b6b',
                pointHoverBorderColor: '#fff',
                tension: 0.4,
                yAxisID: 'y',
            },
            {
                label: 'Transactions',
                data: transactionData,
                borderColor: '#f4a017',
                backgroundColor: gradient2,
                borderWidth: 2.5,
                fill: true,
                pointRadius: 4,
                pointBackgroundColor: '#fff',
                pointBorderColor: '#f4a017',
                pointBorderWidth: 1.5,
                pointHoverRadius: 6,
                tension: 0.4,
                yAxisID: 'y1',
            }
        ]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
            mode: 'index',
            intersect: false,
        },
        plugins: {
            legend: {
                display: true,
                position: 'top',
                labels: {
                    usePointStyle: true,
                    padding: 16,
                    font: { size: 12, weight: '700', family: "'Outfit', sans-serif" },
                    color: '#4a5568',
                    boxPadding: 8,
                    boxWidth: 8,
                }
            },
            tooltip: {
                backgroundColor: 'rgba(0, 0, 0, 0.8)',
                padding: 12,
                titleFont: { size: 13, weight: '700' },
                bodyFont: { size: 12 },
                borderColor: 'rgba(255, 255, 255, 0.2)',
                borderWidth: 1,
                displayColors: true,
                boxPadding: 8,
                usePointStyle: true,
                callbacks: {
                    label: function(context) {
                        let label = context.dataset.label || '';
                        if (label) label += ': ';
                        if (context.parsed.y !== null) {
                            if (context.datasetIndex === 0) {
                                label += '₹ ' + context.parsed.y.toLocaleString('en-IN');
                            } else {
                                label += context.parsed.y + ' txns';
                            }
                        }
                        return label;
                    }
                }
            }
        },
        scales: {
            y: {
                type: 'linear',
                display: true,
                position: 'left',
                title: {
                    display: true,
                    text: 'Revenue (₹)',
                    font: { size: 12, weight: '700' },
                    color: '#ff6b6b'
                },
                ticks: {
                    font: { size: 11, weight: '600' },
                    color: '#94a3b8',
                    callback: function(value) {
                        if (value >= 1000) return '₹' + (value / 1000).toFixed(0) + 'K';
                        return '₹' + value;
                    }
                },
                grid: {
                    color: 'rgba(13, 27, 42, 0.05)',
                    drawBorder: false,
                },
            },
            y1: {
                type: 'linear',
                display: true,
                position: 'right',
                title: {
                    display: true,
                    text: 'Transactions',
                    font: { size: 12, weight: '700' },
                    color: '#f4a017'
                },
                ticks: {
                    font: { size: 11, weight: '600' },
                    color: '#94a3b8',
                },
                grid: {
                    drawOnChartArea: false,
                    drawBorder: false,
                },
            },
            x: {
                ticks: {
                    font: { size: 11, weight: '600' },
                    color: '#94a3b8',
                },
                grid: {
                    color: 'rgba(13, 27, 42, 0.05)',
                    drawBorder: false,
                },
            }
        }
    }
});
</script>
</body>
</html>
