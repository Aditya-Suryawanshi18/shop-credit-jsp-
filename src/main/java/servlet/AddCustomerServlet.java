package servlet;

import javax.servlet.*;
import javax.servlet.http.*;
import java.io.*;
import java.sql.*;
import doa.DBConnection;

public class AddCustomerServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html");
        request.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        String name        = request.getParameter("name");
        String marathiName = request.getParameter("marathiName"); // may be null / blank
        String phone       = request.getParameter("phone");
        String credit      = request.getParameter("credit");
        String address     = request.getParameter("address");

        // Sanitise optional Marathi name
        if (marathiName != null && marathiName.trim().isEmpty()) marathiName = null;
        if (marathiName != null) marathiName = marathiName.trim();

        if (name == null || phone == null || credit == null || address == null ||
                name.isEmpty() || phone.isEmpty() || credit.isEmpty() || address.isEmpty()) {
            out.println("<script>");
            out.println("alert('⚠️ Please fill all required fields!');");
            out.println("window.location.href='add_customer.jsp';");
            out.println("</script>");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {

            String sql = "INSERT INTO customers (id, name, marathi_name, phone, credit, address) "
                       + "VALUES (customer_seq.NEXTVAL, ?, ?, ?, ?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, name.trim());
                ps.setString(2, marathiName);           // NULL if not provided
                ps.setString(3, phone.trim());
                ps.setDouble(4, Double.parseDouble(credit));
                ps.setString(5, address.trim());

                int rows = ps.executeUpdate();

                if (rows > 0) {
                    out.println("<script>");
                    out.println("alert('Customer Added Successfully!');");
                    out.println("window.location.href='add_customer.jsp';");
                    out.println("</script>");
                } else {
                    out.println("<script>");
                    out.println("alert('❌ Failed to add customer!');");
                    out.println("window.location.href='add_customer.jsp';");
                    out.println("</script>");
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
            out.println("<script>");
            out.println("alert('❌ Database Error: " + e.getMessage().replace("'", "") + "');");
            out.println("window.location.href='add_customer.jsp';");
            out.println("</script>");
        } catch (NumberFormatException e) {
            out.println("<script>");
            out.println("alert('❌ Invalid credit amount!');");
            out.println("window.location.href='add_customer.jsp';");
            out.println("</script>");
        }
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("add_customer.jsp");
    }
}
