import numpy as np
import pandas as pd
import plotly.express as px
import streamlit as st
from scipy import stats

st.set_page_config(page_title='Olist | E-Commerce Intelligence', page_icon='📊', layout='wide')
st.markdown('''<style>.block-container{padding-top:1.5rem}.stMetric{background:#f4f7f6;padding:14px;border-radius:12px;border:1px solid #e5e9e7}</style>''',unsafe_allow_html=True)

@st.cache_data
def load():
    orders=pd.read_csv('orders.csv.gz',dtype={'order_id':str,'customer_unique_id':str})
    items=pd.read_csv('items.csv.gz',dtype={'order_id':str})
    orders['delayed']=orders['delayed'].map({'True':True,'False':False,True:True,False:False})
    return orders,items
orders,items=load()
st.title('🛍️ Olist E-Commerce Intelligence')
st.caption('Sales • Customer behavior • Delivery efficiency • Statistical hypothesis testing | Brazilian Olist dataset')

states=sorted(orders.customer_state.dropna().unique())
months=sorted(m for m in orders.month.dropna().unique() if m!='NaT')
with st.sidebar:
    st.header('Explore the data')
    chosen_states=st.multiselect('Customer state',states,default=[])
    start,end=st.select_slider('Purchase month range',options=months,value=(months[0],months[-1]))
    st.caption('Empty state selection means all states. Statistical tests use the current state/month filters.')
mask=orders.month.between(start,end)
if chosen_states:mask &= orders.customer_state.isin(chosen_states)
o=orders.loc[mask].copy()
i=items.loc[items.month.between(start,end) & (items.customer_state.isin(chosen_states) if chosen_states else True)].copy()
if o.empty:st.warning('No orders match these filters.');st.stop()

valid_delivery=o[o.delayed.notna()]
rate=(~valid_delivery.delayed.astype(bool)).mean()*100 if len(valid_delivery) else np.nan
cols=st.columns(5)
metrics=[('Sales (item price)',f'R${i.price.sum()/1e6:,.2f}M'),('Orders',f'{o.order_id.nunique():,}'),('Customers',f'{o.customer_unique_id.nunique():,}'),('On-time deliveries',f'{rate:.2f}%' if np.isfinite(rate) else 'N/A'),('Avg. review',f'{o.review_score.mean():.2f}/5')]
for c,(name,value) in zip(cols,metrics):c.metric(name,value)

left,right=st.columns(2)
with left:
    sales=i.groupby('month',as_index=False).price.sum().sort_values('month')
    st.plotly_chart(px.line(sales,x='month',y='price',markers=True,title='Monthly sales trend',labels={'price':'Sales (R$)','month':'Month'}),use_container_width=True)
with right:
    cats=i.groupby('category',as_index=False).price.sum().nlargest(10,'price').sort_values('price')
    st.plotly_chart(px.bar(cats,x='price',y='category',orientation='h',title='Top 10 categories by sales',labels={'price':'Sales (R$)','category':''}),use_container_width=True)

st.subheader('🧪 Hypothesis Testing Lab')
st.caption('Exploratory associations, not causal claims. α = 0.05. Tests are calculated from filtered order-level records; missing observations are excluded.')
test=st.selectbox('Choose a business hypothesis',[
    'Delivery time vs. review score (Spearman)',
    'Repeat vs. one-time customer order value (Mann–Whitney U)',
    'Delivery delays by state (Chi-square)',
    'Order value across payment types (Kruskal–Wallis)'])

def result(stat,p,n,meaning,extra=''):
    a,b,c=st.columns(3)
    a.metric('Test statistic',f'{stat:.4f}')
    b.metric('p-value',f'{p:.3g}')
    c.metric('Observations',f'{n:,}')
    st.write(('**Reject H₀** at α = 0.05.' if p<0.05 else '**Do not reject H₀** at α = 0.05.')+' '+meaning)
    if extra:st.caption(extra)

if test.startswith('Delivery time'):
    st.write('**H₀:** No monotonic association between delivery time and review score. **H₁:** An association exists.')
    d=o.loc[o.order_status.eq('delivered'),['delivery_days','review_score']].dropna()
    d=d[d.delivery_days>=0]
    if len(d)>2 and d.delivery_days.nunique()>1 and d.review_score.nunique()>1:
        r,p=stats.spearmanr(d.delivery_days,d.review_score)
        result(r,p,len(d),'The sample provides '+('evidence of an association.' if p<.05 else 'insufficient evidence of an association.'),f'Spearman ρ = {r:.3f}; association does not establish causation.')
        st.plotly_chart(px.box(d,x='review_score',y='delivery_days',title='Delivery time by review rating',labels={'review_score':'Review score','delivery_days':'Delivery days'}),use_container_width=True)
    else:st.info('Not enough non-missing, varying observations for this test.')
elif test.startswith('Repeat'):
    st.write('**H₀:** Order-value distributions are the same for repeat and one-time customers. **H₁:** They differ.')
    d=o[['customer_unique_id','item_sales']].dropna().copy()
    counts=d.groupby('customer_unique_id').size()
    d['repeat']=d.customer_unique_id.map(counts)>1
    x=d.loc[d.repeat,'item_sales'];y=d.loc[~d.repeat,'item_sales']
    if len(x)>0 and len(y)>0:
        stat,p=stats.mannwhitneyu(x,y,alternative='two-sided')
        result(stat,p,len(d),'Compare group medians and distributions before interpreting the difference.',f'Repeat median R${x.median():.2f}; one-time median R${y.median():.2f}. Repeat status is defined within the selected period.')
        st.plotly_chart(px.box(d.assign(group=np.where(d.repeat,'Repeat','One-time')),x='group',y='item_sales',title='Order values by customer frequency',points=False),use_container_width=True)
    else:st.info('Both customer groups are required.')
elif test.startswith('Delivery delays'):
    st.write('**H₀:** Delay status is independent of customer state. **H₁:** They are associated.')
    d=o[['customer_state','delayed']].dropna().copy()
    table=pd.crosstab(d.customer_state,d.delayed)
    if table.shape[0]>1 and table.shape[1]==2:
        stat,p,dof,expected=stats.chi2_contingency(table)
        if (expected<5).any():st.warning('Some expected cell counts are below 5; chi-square approximation may be unreliable. Consider combining sparse states.')
        cramers=np.sqrt(stat/(table.to_numpy().sum()*min(table.shape[0]-1,table.shape[1]-1)))
        result(stat,p,len(d),'State and delay status '+('show statistical association.' if p<.05 else 'do not show sufficient evidence of association.'),f'Cramér’s V = {cramers:.3f}; degrees of freedom = {dof}.')
        rates=d.groupby('customer_state').delayed.agg(['mean','size']).reset_index()
        rates['mean']=rates['mean'].astype(float)*100
        st.plotly_chart(px.bar(rates.sort_values('mean',ascending=False),x='customer_state',y='mean',title='Delayed deliveries by state',labels={'mean':'Delay rate (%)','customer_state':'State'}),use_container_width=True)
    else:st.info('At least two states and both delay outcomes are required.')
else:
    st.write('**H₀:** Order-value distributions are equal across payment types. **H₁:** At least one differs.')
    d=o[['payment_type','item_sales']].dropna().copy()
    counts=d.payment_type.value_counts();d=d[d.payment_type.isin(counts[counts>=5].index)]
    groups=[g.item_sales.to_numpy() for _,g in d.groupby('payment_type')]
    if len(groups)>1:
        stat,p=stats.kruskal(*groups)
        epsilon=max(0,(stat-len(groups)+1)/(len(d)-len(groups))) if len(d)>len(groups) else np.nan
        result(stat,p,len(d),'At least one group may differ.' if p<.05 else 'No statistically significant difference detected.',f'Epsilon-squared (approx.) = {epsilon:.3f}. Payment type is the largest-value payment record per order; item price excludes freight.')
        st.plotly_chart(px.box(d,x='payment_type',y='item_sales',title='Order value by primary payment type',points=False),use_container_width=True)
    else:st.info('At least two payment groups with five orders each are required.')

st.divider()
st.caption('Methodology: Sales = sum of order-item prices. On-time delivery compares calendar dates for delivered orders with both dates available. Multiple review records are averaged per order. Data are observational; p-values do not establish causation. Source: Olist Brazilian E-Commerce Public Dataset.')
