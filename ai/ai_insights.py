"""
ai_insights.py
---------------
Pulls real metrics from the PostgreSQL database (same numbers used in
sql/03_sales_analysis.sql and sql/05_product_analysis.sql) and sends
them to Gemini to generate a short executive summary. The LLM only
summarizes real numbers — it never invents anything on its own.

Run with:
    python3 ai_insights.py
"""

import os
import psycopg2
from google import genai
from dotenv import load_dotenv

# load the key from .env so it never gets committed to git
load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY not found. Make sure it's set in your .env file.")

client = genai.Client(api_key=GEMINI_API_KEY)


def get_metrics():
    """Pulls the core metrics already validated in the SQL scripts."""
    conn = psycopg2.connect(
        dbname="ecommerce_analytics",
        user="parth",
        host="localhost"
    )
    cur = conn.cursor()

    metrics = {}

    # overall revenue summary
    cur.execute("""
        SELECT COUNT(*), ROUND(SUM(price + shipping_charges), 2), ROUND(AVG(price + shipping_charges), 2)
        FROM orders WHERE order_status = 'delivered';
    """)
    total_orders, total_revenue, avg_order_value = cur.fetchone()
    metrics['total_orders'] = total_orders
    metrics['total_revenue'] = float(total_revenue)
    metrics['avg_order_value'] = float(avg_order_value)

    # top category by revenue
    cur.execute("""
        SELECT p.product_category_name, ROUND(SUM(o.price + o.shipping_charges), 2) AS revenue
        FROM orders o
        JOIN products p ON o.product_id = p.product_id
        WHERE o.order_status = 'delivered'
        GROUP BY p.product_category_name
        ORDER BY revenue DESC
        LIMIT 1;
    """)
    top_category, top_category_revenue = cur.fetchone()
    metrics['top_category'] = top_category
    metrics['top_category_revenue'] = float(top_category_revenue)

    # on-time vs late delivery rate
    cur.execute("""
        SELECT
            ROUND(100.0 * COUNT(*) FILTER (WHERE order_delivered_timestamp <= order_estimated_delivery_date) / COUNT(*), 1) AS on_time_pct
        FROM orders
        WHERE order_status = 'delivered' AND order_delivered_timestamp IS NOT NULL;
    """)
    (on_time_pct,) = cur.fetchone()
    metrics['on_time_pct'] = float(on_time_pct)

    # top payment method
    cur.execute("""
        SELECT payment_type, COUNT(*) AS cnt
        FROM orders
        WHERE order_status = 'delivered'
        GROUP BY payment_type
        ORDER BY cnt DESC
        LIMIT 1;
    """)
    top_payment_type, top_payment_count = cur.fetchone()
    metrics['top_payment_type'] = top_payment_type
    metrics['top_payment_pct'] = round(100 * top_payment_count / total_orders, 1)

    cur.close()
    conn.close()
    return metrics


def generate_summary(metrics):
    """Sends the metrics to Gemini and asks for a short summary."""
    prompt = f"""
You are a business analyst writing a short executive summary for an
e-commerce sales dashboard. Use ONLY the numbers provided below — do
not invent, estimate, or assume any additional figures.

Data:
- Total delivered orders: {metrics['total_orders']:,}
- Total revenue: ${metrics['total_revenue']:,.2f}
- Average order value: ${metrics['avg_order_value']:.2f}
- Top-performing category by revenue: {metrics['top_category']} (${metrics['top_category_revenue']:,.2f})
- On-time delivery rate: {metrics['on_time_pct']}%
- Most common payment method: {metrics['top_payment_type']} ({metrics['top_payment_pct']}% of orders)

Write a 3-4 sentence executive summary suitable for a business
stakeholder skimming a dashboard. Be direct and specific with numbers,
not vague. Do not use markdown formatting.
"""

    response = client.models.generate_content(
        model='gemini-3.5-flash',
        contents=prompt
    )
    return response.text


if __name__ == "__main__":
    print("Pulling metrics from database...")
    metrics = get_metrics()

    print("\nMetrics retrieved:")
    for key, value in metrics.items():
        print(f"  {key}: {value}")

    print("\nGenerating summary with Gemini...\n")
    summary = generate_summary(metrics)

    print("=" * 60)
    print("EXECUTIVE SUMMARY")
    print("=" * 60)
    print(summary)
