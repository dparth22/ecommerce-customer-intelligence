# Model Results — Late Delivery Prediction

## Why this task
Every customer in this dataset only placed one order, so I couldn't do
churn or repeat-purchase modeling. Instead I picked late delivery
prediction, since the data already has what I need: I can compare
`order_delivered_timestamp` to `order_estimated_delivery_date` and get
a clear yes/no label.

I also checked earlier (in the EDA notebook) whether price correlates
with things like shipping cost or product weight, and it basically
doesn't. That told me predicting price wasn't going to work well, so I
didn't try it.

## Setup
- Target: `is_late` — 1 if delivered after the estimated date, 0 if not
- Only used delivered orders that have a real delivery date (87,422 rows)
- Class split: 92.3% on-time, 7.7% late — pretty imbalanced, so I used `class_weight='balanced'`
- Features: price, shipping charges, payment type/installments/value, product category, customer state, purchase month, day of week
- Split 80/20 train/test, stratified so both sets keep the same late/on-time ratio

## Models I tried

| Model | Accuracy | Precision (late) | Recall (late) | F1 (late) |
|---|---|---|---|---|
| Logistic Regression | 0.68 | 0.12 | 0.51 | 0.20 |
| Random Forest | 0.74 | 0.15 | 0.52 | 0.23 |

Random Forest did a bit better across the board, so I kept that as the
final model.

## Honest results
Neither model is very accurate. Precision for the late class is low
(12-15%), so most of the model's "this will be late" predictions are
wrong. I don't want to oversell this.

Given how weak the correlations were in my EDA, this makes sense — the
features I have just don't explain delivery lateness that well. The
real drivers are probably things not in this dataset, like actual
shipping distance or which carrier handled the order.

## What I did find (feature importance)
Even though accuracy is low, checking which features the model relied
on most gave a real, explainable result:

- **Purchase month mattered the most by far** — about 2x more than any
  other feature. This matches the November revenue spike I found in
  the EDA notebook — busier months probably strain delivery and cause
  more delays.
- After that, a handful of **states** (SP, RJ, MG, BA, PR — same states
  that lead in revenue) were the next most important features, which
  suggests geography/logistics matters too.
- Price, payment method, and product category barely mattered compared
  to when and where the order was placed.

## Takeaway
The model itself isn't very accurate, but the feature importance is
still a useful finding on its own: late deliveries seem to depend more
on timing and location than on what was bought or how it was paid for.
