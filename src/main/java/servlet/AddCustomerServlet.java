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
        PrintWriter out = response.getWriter();

        String name    = request.getParameter("name");
        String phone   = request.getParameter("phone");
        String credit  = request.getParameter("credit");
        String address = request.getParameter("address");

        if (name == null || phone == null || credit == null || address == null ||
                name.isEmpty() || phone.isEmpty() || credit.isEmpty() || address.isEmpty()) {
            out.println("<script>");
            out.println("alert('⚠️ Please fill all fields!');");
            out.println("window.location.href='add_customer.jsp';");
            out.println("</script>");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {

            String sql = "INSERT INTO customers (id, name, phone, credit, address) "
                       + "VALUES (customer_seq.NEXTVAL, ?, ?, ?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, name);
                ps.setString(2, phone);
                ps.setDouble(3, Double.parseDouble(credit));
                ps.setString(4, address);

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