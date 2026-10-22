from pathlib import Path
import pandas as pd
ROOT=Path(__file__).resolve().parent
SOURCE=ROOT/'raw'
def read(n):return pd.read_csv(SOURCE/n)
orders=read('olist_orders_dataset.csv')
customers=read('olist_customers_dataset.csv')[['customer_id','customer_unique_id','customer_state']]
items=read('olist_order_items_dataset.csv')
products=read('olist_products_dataset.csv')[['product_id','product_category_name']]
translation=read('product_category_name_translation.csv')
reviews=read('olist_order_reviews_dataset.csv')[['order_id','review_score']].groupby('order_id',as_index=False)['review_score'].mean()
payments=read('olist_order_payments_dataset.csv')
for c in ['order_purchase_timestamp','order_delivered_customer_date','order_estimated_delivery_date']:
 orders[c]=pd.to_datetime(orders[c],errors='coerce')
order_items=items.merge(products,on='product_id',how='left').merge(translation,on='product_category_name',how='left')
order_items['category']=order_items['product_category_name_english'].fillna(order_items['product_category_name']).fillna('Unknown')
order_items=order_items.merge(orders[['order_id','order_purchase_timestamp','customer_id']],on='order_id',how='left').merge(customers,on='customer_id',how='left')
order_items['month']=order_items['order_purchase_timestamp'].dt.to_period('M').astype(str)
order_items[['order_id','customer_state','category','month','price','freight_value']].to_csv(ROOT/'items.csv.gz',index=False,compression='gzip')
amount=items.groupby('order_id',as_index=False).agg(item_sales=('price','sum'),freight=('freight_value','sum'),item_count=('order_item_id','size'))
# Select payment type with highest payment value per order for a single-valued grouping.
primary=payments.sort_values('payment_value',ascending=False).drop_duplicates('order_id')[['order_id','payment_type']]
order=orders.merge(customers,on='customer_id',how='left').merge(amount,on='order_id',how='left').merge(reviews,on='order_id',how='left').merge(primary,on='order_id',how='left')
order['delivery_days']=(order['order_delivered_customer_date']-order['order_purchase_timestamp']).dt.total_seconds()/86400
order['delayed']=pd.NA
valid=(order.order_status.eq('delivered') & order.order_delivered_customer_date.notna() & order.order_estimated_delivery_date.notna())
order.loc[valid, 'delayed'] = (
    order.loc[valid, 'order_delivered_customer_date']
    > order.loc[valid, 'order_estimated_delivery_date']
)
order['month']=order['order_purchase_timestamp'].dt.to_period('M').astype(str)
cols=['order_id','customer_unique_id','customer_state','order_status','month','item_sales','freight','item_count','review_score','delivery_days','delayed','payment_type']
order[cols].to_csv(ROOT/'orders.csv.gz',index=False,compression='gzip')
print('Generated',len(order),'orders and',len(order_items),'items')
