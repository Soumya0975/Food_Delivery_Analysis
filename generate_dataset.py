"""Synthetic Indian food-delivery dataset generator (PostgreSQL-ready CSVs).
Schema is inspired by a public 4-table food-sales model (customers/orders/order_item/product);
all data here is randomly generated. Seeded for reproducibility."""
import csv, random, os
from datetime import date, timedelta

random.seed(42)
N_CUST, N_ORD = 600, 4000
START, END = date(2025, 1, 1), date(2026, 9, 30)

first = ["Aarav","Vivaan","Aditya","Arjun","Rohan","Karan","Siddharth","Ishaan","Rahul","Amit","Vikram","Nikhil","Pranav","Yash","Harsh",
         "Ananya","Diya","Priya","Neha","Sneha","Pooja","Kavya","Isha","Riya","Meera","Shreya","Aditi","Nisha","Tanvi","Sakshi"]
last = ["Sharma","Patil","Deshmukh","Kulkarni","Gupta","Verma","Iyer","Nair","Reddy","Rao","Singh","Mehta","Joshi","Shah","Khan",
        "Banerjee","Chatterjee","Pillai","Bhat","Wankhede","Thakur","Pandey","Mishra","Jain","Agarwal"]
cities = [("Mumbai","Maharashtra",14),("Pune","Maharashtra",10),("Nagpur","Maharashtra",8),("Delhi","Delhi",14),("Bengaluru","Karnataka",12),
          ("Hyderabad","Telangana",9),("Chennai","Tamil Nadu",8),("Kolkata","West Bengal",7),("Ahmedabad","Gujarat",6),("Jaipur","Rajasthan",5),("Indore","Madhya Pradesh",4)]
# (name, category, description, cost, price) in INR
products = [
 ("Butter Chicken","Main Course","Creamy tomato-butter gravy with tandoori chicken",140,280),
 ("Paneer Butter Masala","Main Course","Cottage cheese in rich tomato gravy",120,240),
 ("Dal Makhani","Main Course","Slow-cooked black lentils with cream",80,190),
 ("Chicken Biryani","Rice","Hyderabadi dum biryani with raita",130,260),
 ("Veg Biryani","Rice","Basmati rice with vegetables and spices",90,200),
 ("Jeera Rice","Rice","Cumin-tempered basmati rice",40,110),
 ("Masala Dosa","South Indian","Crisp dosa with potato filling, sambar, chutney",50,130),
 ("Idli Sambar (3 pcs)","South Indian","Steamed rice cakes with sambar",35,90),
 ("Medu Vada (2 pcs)","South Indian","Fried lentil doughnuts",30,80),
 ("Vada Pav","Street Food","Mumbai-style potato fritter in bun",12,35),
 ("Pav Bhaji","Street Food","Spiced vegetable mash with buttered pav",55,140),
 ("Pani Puri (6 pcs)","Street Food","Crisp puris with spiced water",20,60),
 ("Samosa (2 pcs)","Snacks","Potato-pea stuffed pastry",18,50),
 ("Paneer Tikka","Starters","Tandoor-grilled marinated paneer",90,220),
 ("Chicken Tikka","Starters","Tandoor-grilled marinated chicken",100,240),
 ("Garlic Naan","Breads","Tandoor naan with garlic butter",15,55),
 ("Butter Roti","Breads","Whole wheat roti with butter",8,30),
 ("Chole Bhature","North Indian","Chickpea curry with fried bread",60,150),
 ("Rajma Chawal","North Indian","Kidney bean curry with rice",55,140),
 ("Poha","Breakfast","Flattened rice with peanuts and lemon",25,70),
 ("Misal Pav","Street Food","Spicy sprouts curry with pav",40,110),
 ("Saoji Chicken","Main Course","Nagpur-style spicy chicken curry",120,260),
 ("Gulab Jamun (2 pcs)","Dessert","Milk-solid dumplings in sugar syrup",20,70),
 ("Rasmalai (2 pcs)","Dessert","Cottage-cheese discs in saffron milk",35,110),
 ("Jalebi (100g)","Dessert","Crisp saffron syrup spirals",25,80),
 ("Masala Chai","Beverages","Spiced Indian tea",8,30),
 ("Sweet Lassi","Beverages","Chilled sweetened yogurt drink",20,75),
 ("Mango Lassi","Beverages","Yogurt drink with Alphonso mango",30,95),
 ("Filter Coffee","Beverages","South Indian decoction coffee",12,45),
 ("Fresh Lime Soda","Beverages","Sweet or salted lime soda",10,50),
]
pay = [("UPI",55),("COD",20),("Credit/Debit Card",18),("Wallet",7)]
rev_pos = ["Delicious and arrived hot","Great taste, will order again","Perfect spice level","Quick delivery, fresh food","Loved the portion size","Authentic flavours"]
rev_neu = ["Okay, nothing special","Food was fine but delivery was slow","Average taste","Portion could be bigger"]
rev_neg = ["Food arrived cold","Too oily, not good","Wrong item delivered","Very late delivery"]

def wchoice(pairs): return random.choices([p[0] for p in pairs],[p[-1] for p in pairs])[0]

# customers
customers=[]
cw=[(c,s,w) for c,s,w in cities]
for i in range(1,N_CUST+1):
    city,state,_=random.choices(cw,[c[2] for c in cw])[0]
    signup=START+timedelta(days=random.randint(0,(END-START).days-30))
    ref=random.randint(1,i-1) if i>1 and random.random()<0.22 else ""
    customers.append([i,f"{random.choice(first)} {random.choice(last)}",city,state,signup.isoformat(),ref])

# date weights: weekends, festive months (Oct-Nov Diwali, Mar Holi), mild monsoon dip
days=[START+timedelta(days=d) for d in range((END-START).days+1)]
def dw(d):
    w=1.0
    if d.weekday()>=5: w*=1.35
    if d.month in (10,11): w*=1.4
    if d.month==3: w*=1.2
    if d.month in (7,8): w*=0.9
    return w
dweights=[dw(d) for d in days]

orders,items=[],[]
oid=iid=0
cust_by_id={c[0]:c for c in customers}
repeat_pool=[c[0] for c in customers]
heavy=random.sample(repeat_pool,120)  # loyal users order more
for _ in range(N_ORD):
    oid+=1
    cid=random.choice(heavy) if random.random()<0.45 else random.choice(repeat_pool)
    signup=date.fromisoformat(cust_by_id[cid][4])
    for _try in range(20):
        d=random.choices(days,dweights)[0]
        if d>=signup: break
    else: d=signup
    prods=random.sample(range(len(products)),random.randint(1,5))
    total=0
    for p in prods:
        iid+=1; q=random.choices([1,2,3],[70,24,6])[0]
        price=products[p][4]; total+=q*price
        items.append([iid,oid,p+1,q,price])
    tip=random.choice([0,0,0,10,20,30,50]) if total<500 else random.choice([0,20,50,100])
    r=random.choices([5,4,3,2,1,None],[34,30,12,6,4,14])[0]
    review="" if r is None else random.choice(rev_pos if r>=4 else rev_neu if r==3 else rev_neg)
    orders.append([oid,cid,d.isoformat(),wchoice(pay),tip,"" if r is None else r,review])
orders.sort(key=lambda x:x[2])
# re-number so order_id follows chronology
remap={o[0]:i+1 for i,o in enumerate(orders)}
for o in orders: o[0]=remap[o[0]]
for it in items: it[1]=remap[it[1]]
items.sort(key=lambda x:x[1])
for i,it in enumerate(items): it[0]=i+1

OUT=os.path.join(os.path.dirname(os.path.abspath(__file__)),"..","data")
def w(name,header,rows):
    with open(os.path.join(OUT,name),"w",newline="",encoding="utf-8") as f:
        c=csv.writer(f); c.writerow(header); c.writerows(rows)
w("customers.csv",["customer_id","customer_name","city","state","signup_date","referred_by"],customers)
w("product.csv",["product_id","product_name","category","description","cost_inr","price_inr"],[[i+1,*p] for i,p in enumerate(products)])
w("orders.csv",["order_id","customer_id","order_date","payment_method","tip_inr","rating","review_text"],orders)
w("order_item.csv",["order_item_id","order_id","product_id","quantity","unit_price_inr"],items)
print(len(customers),len(products),len(orders),len(items))
