import math

Q96 = 2 ** 96

def price_to_tick(price):
    return math.floor(math.log(price, 1.0001))

def price_to_q96(price):
    return int(math.sqrt(price) * Q96)


sqrtp_low = price_to_q96(4545)
sqrtp_curr = price_to_q96(5000)
sqrtp_upper = price_to_q96(5500)

def calculate_liquidity_0(amount, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return (amount * (pa * pb) / Q96) / (pb - pa)
    

def calculate_liquidity_1(amount, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return amount * Q96 / (pb - pa)

def calculate_x(liquidity, pa, pb):
    if pa > pb:
        pa, pb = pb, pa 
    return int(liquidity * Q96 * (pb - pa) / pa / pb)


def calculate_y(liquidity, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return int(liquidity * (pb - pa) / Q96)



# putting in 1 eth and 5000 usdc
eth = 10**18
amount_eth = 1 * eth
amount_usdc = 5000 * eth

liq0 = calculate_liquidity_0(amount_eth, sqrtp_curr, sqrtp_upper)
liq1 = calculate_liquidity_1(amount_usdc, sqrtp_curr, sqrtp_low)
liq = int(min(liq0, liq1))
print(liq)

# calculating x and y values based on provided liquidity to 
amount0 = calculate_x(liq, sqrtp_upper, sqrtp_curr)
amount1 = calculate_y(liq, sqrtp_low, sqrtp_curr)
print(amount0, amount1)
