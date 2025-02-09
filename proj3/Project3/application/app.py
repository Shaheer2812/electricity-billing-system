from fastapi import FastAPI, Request, Form
from fastapi.middleware.cors import CORSMiddleware 
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from fastapi import HTTPException

import datetime
import os
import logging
import oracledb
import uvicorn

d = os.environ.get("ORACLE_HOME")               # Defined by the file `oic_setup.sh`
oracledb.init_oracle_client(lib_dir=d)          # Thick mode
# print(d)
# These environment variables come from `env.sh` file.
user_name = os.environ.get("DB_USERNAME")
user_pswd = os.environ.get("DB_PASSWORD")
db_alias  = os.environ.get("DB_ALIAS")


import os

# d = "/home/ubuntu/oracle/instantclient"
# print("Directory contents:")
# print(os.listdir(d))
# make sure to setup connection with the DATABASE SERVER FIRST. refer to python-oracledb documentation for more details on how to connect, and run sql queries and PL/SQL procedures.
connection = oracledb.connect(
    user=user_name,
    password=user_pswd,
    dsn=db_alias
)


app = FastAPI()

logger = logging.getLogger('uvicorn.error')
logger.setLevel(logging.DEBUG)

origins = ['*']

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
) 
app.mount("/static", StaticFiles(directory="static"), name="static")

templates = Jinja2Templates(directory="templates")


# -----------------------------
# API Endpoints
# -----------------------------

# ---------- GET methods for the pages ----------
@app.get("/", response_class=HTMLResponse)
async def get_index(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

# Bill payment page
@app.get("/bill-payment", response_class=HTMLResponse)
async def get_bill_payment(request: Request):
    return templates.TemplateResponse("bill_payment.html", {"request": request})

# Bill generation page
@app.get("/bill-retrieval", response_class=HTMLResponse)
async def get_bill_retrieval(request: Request):
    return templates.TemplateResponse("bill_retrieval.html", {"request": request})

# Adjustments page
@app.get("/bill-adjustments", response_class=HTMLResponse)
async def get_bill_adjustment(request: Request):
    return templates.TemplateResponse("bill_adjustment_form.html", {"request": request})

# ---------- POST methods for the pages ----------


@app.post("/bill-payment", response_class=HTMLResponse)
async def post_bill_payment(request: Request, bill_id: int = Form(...), amount: float = Form(...), payment_method_id: int = Form(...)):
    # Handle billing payment here

    # Retrive the details required in the dictionary, by querying your database, or running appropriate functions
    try:
        cursor = connection.cursor()
        
        result = cursor.callfunc(
            "fun_process_Payment",
            oracledb.NUMBER,
            [
                bill_id, 
                datetime.datetime.now(), 
                payment_method_id, 
                amount
            ]
        )

        cursor.execute(
            """
            SELECT 
                pd.PaymentStatus, 
                pd.AmountPaid, 
                b.TotalAmount_BeforeDueDate, 
                pm.PaymentMethodDescription AS payment_method_description
            FROM PaymentDetails pd
            JOIN Bill b ON pd.BillID = b.BillID
            JOIN PaymentMethods pm ON pd.PaymentMethodID = pm.PaymentMethodID
            WHERE pd.BillID = :bill_id
            AND pd.PaymentDate = (
                SELECT MAX(PaymentDate) 
                FROM PaymentDetails 
                WHERE BillID = :bill_id
            )
        """, bill_id=bill_id)

        payment_info = cursor.fetchone()

        if payment_info:
            total_amount = payment_info[2]  
            amount_paid = payment_info[1]  
            outstanding_amount = total_amount - amount_paid  
        else:
            outstanding_amount = 0.0  

        payment_details = {
            "bill_id": bill_id,
            "amount": amount,
            "payment_method_id": payment_method_id,
            "payment_method_description": payment_info[3] if payment_info else "Unknonw",
            "payment_date": datetime.datetime.now(),
            "payment_status": payment_info[0] if payment_info else "Processed",
            "outstanding_amount": outstanding_amount,
        }

        connection.commit()
        
        return templates.TemplateResponse(
            "payment_receipt.html", 
            {"request": request, "payment_details": payment_details}
        )
   
    finally:
        if cursor:
            cursor.close()
        
@app.post("/bill-retrieval", response_class=HTMLResponse)
async def post_bill_retrieval(request: Request, customer_id: str = Form(...), connection_id: str = Form(...), month: str = Form(...), year: str = Form(...)):
    # Here, you would generate the bill

    # Retrive the details required in the dictionary, by querying your database, or running appropriate functions
    try:

        cursor = connection.cursor()

        billing_date = f"{int(year)}-{int(month):02d}-01"  

        fixed_fee_query = """
        SELECT fc.FixedChargeType, fc.FixedFee
        FROM FixedCharges fc
        JOIN Connections c ON fc.ConnectionTypeCode = c.ConnectionTypeCode
        WHERE c.ConnectionID = :connection_id
        AND fc.StartDate <= TO_DATE(:billing_date, 'YYYY-MM-DD')
        AND fc.EndDate >= TO_DATE(:billing_date, 'YYYY-MM-DD')
        """

        cursor.execute(fixed_fee_query, {"connection_id": connection_id, "billing_date": billing_date})
        fixed_fees = cursor.fetchall()

        fixed_fee_details = [
            {"name": fee[0], "amount": float(fee[1])} for fee in fixed_fees
        ]

        tariff_query = """
        SELECT 
            t.TarrifDescription, 
            NVL(t.MinUnit, 0) AS MinUnit, 
            NVL(t.RatePerUnit, 0) AS RatePerUnit, 
            NVL(t.MinAmount, 0) AS MinAmount
        FROM Tariff t
        JOIN Connections c ON t.ConnectionTypeCode = c.ConnectionTypeCode
        WHERE c.ConnectionID = :connection_id
        AND t.StartDate <= TO_DATE(:billing_date, 'YYYY-MM-DD')
        AND t.EndDate >= TO_DATE(:billing_date, 'YYYY-MM-DD')
        ORDER BY t.Slab
        """

        cursor.execute(tariff_query, {"connection_id": connection_id, "billing_date": billing_date})
        tariffs = cursor.fetchall()

        tariff_details = [
            {
                "name": tariff[0],               
                "units": int(tariff[1]),                
                "rate": float(tariff[2]),      
                "amount": float(tariff[1]) * float(tariff[2])  # Amount = Units * Rate per unit
            }
            for tariff in tariffs
        ]

        #  subsidy details
        subsidy_query = """
        SELECT 
            s.SubsidyDescription, 
            sp.ProviderName, 
            s.RatePerUnit
        FROM Subsidy s
        JOIN SubsidyProvider sp ON s.ProviderID = sp.ProviderID
        JOIN Connections c ON s.ConnectionTypeCode = c.ConnectionTypeCode
        WHERE c.ConnectionID = :connection_id
        AND s.StartDate <= TO_DATE(:billing_date, 'YYYY-MM-DD')
        AND s.EndDate >= TO_DATE(:billing_date, 'YYYY-MM-DD')
        """

        cursor.execute(subsidy_query, {"connection_id": connection_id, "billing_date": billing_date})
        subsidies = cursor.fetchall()

        subsidy_details = [
            {
                "name": subsidy[0],                 
                "provider_name": subsidy[1],        
                "rate_per_unit": float(subsidy[2])  
            }
            for subsidy in subsidies
        ]

        prev_bills_query = """
            SELECT 
                b.BillingYear || '-' || LPAD(TO_CHAR(b.BillingMonth), 2, '0') AS bill_month,
                b.TotalAmount_AfterDueDate AS amount,
                TO_CHAR(b.DueDate, 'YYYY-MM-DD') AS due_date,
                CASE 
                    WHEN EXISTS (SELECT 1 FROM PaymentDetails pd WHERE pd.BillID = b.BillID AND pd.PaymentStatus = 'Paid') 
                    THEN 'Paid' 
                    ELSE 'Unpaid' 
                END AS status
            FROM Bill b
            WHERE b.ConnectionID = :connection_id
            AND (b.BillingYear < :year OR (b.BillingYear = :year AND b.BillingMonth < :month))
            ORDER BY b.BillingYear DESC, b.BillingMonth DESC
            FETCH FIRST 5 ROWS ONLY
        """

        cursor.execute(prev_bills_query, {
            "connection_id": connection_id, 
            "year": int(year), 
            "month": int(month)
        })

        prev_bills = cursor.fetchall()

        bills_prev = [
            {
                "month": bill[0],  

                # amount after due date
                "amount": float(bill[1]),  
                "due_date": bill[2], 
                "status": bill[3] 
            } 
            for bill in prev_bills
        ]

        # Query for the bill details for the , connection, month, and year
        query = """
            SELECT 
                b.BillID, b.ConnectionID, b.BillingMonth, b.BillingYear, b.BillIssueDate,
                b.Import_PeakUnits, b.Import_OffPeakUnits, b.Export_PeakUnits, b.Export_OffPeakUnits,
                b.Net_PeakUnits, b.Net_OffPeakUnits, b.PeakAmount, b.OffPeakAmount, b.FixedFee,
                b.TaxAmount, b.Arrears, b.AdjustmentAmount, b.SubsidyAmount, b.DueDate,
                b.TotalAmount_BeforeDueDate, b.TotalAmount_AfterDueDate,
                c.CustomerID, 
                cus.FirstName || ' ' || cus.LastName AS CustomerName, 
                cus.Address, 
                cus.PhoneNumber, 
                cus.Email, 
                c.InstallationDate,
                c.MeterType,
                ct.Description AS ConnectionTypeName, 
                di.DivisionName, 
                di.SubDivName
            FROM Bill b
            JOIN Connections c ON b.ConnectionID = c.ConnectionID
            JOIN Customers cus ON c.CustomerID = cus.CustomerID
            JOIN ConnectionTypes ct ON c.ConnectionTypeCode = ct.ConnectionTypeCode
            JOIN DivInfo di ON c.DivisionID = di.DivisionID AND c.SubDivID = di.SubDivID
            WHERE c.CustomerID = :customer_id
            AND b.ConnectionID = :connection_id
            AND b.BillingMonth = :month
            AND b.BillingYear = :year
        """

        cursor.execute(query, {
            "customer_id": customer_id, 
            "connection_id": connection_id, 
            "month": int(month), 
            "year": int(year)
        })
        
        bill_result = cursor.fetchone()

        bill_details = {
            "bill_id": bill_result[0],                    
            "connection_id": bill_result[1],              
            "customer_name": bill_result[22],             
            "customer_address": bill_result[23],         
            "customer_phone": bill_result[24],           
            "customer_email": bill_result[25],            
            "connection_type": bill_result[28],           
            "division": bill_result[29],                  
            "subdivision": bill_result[30],               
            "installation_date": bill_result[26] if bill_result[26] else None, 
            "meter_type": bill_result[27],               
            "issue_date": bill_result[4],                 
            "net_peak_units": bill_result[9],            
            "net_off_peak_units": bill_result[10],        
            "bill_amount": float(bill_result[19]),      
            "due_date": bill_result[18],                 
            "amount_after_due_date": float(bill_result[20]), 
            "month": month,                              
            "arrears_amount": float(bill_result[15]),     
            "fixed_fee_amount": float(bill_result[13]),  
            "tax_amount": float(bill_result[14]),        

            # hardcoded for now
            "tariffs": tariff_details,
            "taxes": [
                {"name": "GST", "amount": float(bill_result[14] * 0.5)},
                {"name": "Electricity Duty", "amount": float(bill_result[14] * 0.5)},
            ],
            "subsidies": subsidy_details,
            "fixed_fee": fixed_fee_details,
            "bills_prev": bills_prev
        }

        return templates.TemplateResponse("bill_details.html", {"request": request, "bill_details": bill_details})

    finally:
        if cursor:
            cursor.close()

@app.post("/bill-adjustments", response_class=HTMLResponse)
async def post_bill_adjustments(
    request: Request,
    bill_id: int = Form(...),
    officer_name: str = Form(...),
    officer_designation: str = Form(...),
    original_bill_amount: float = Form(...),
    adjustment_amount: float = Form(...),
    adjustment_reason: str = Form(...),
):
    try:
        cursor = connection.cursor()

        cursor.execute("SELECT NVL(MAX(AdjustmentID), 0) + 1 FROM BillAdjustments")
        adjustment_id = cursor.fetchone()[0]

        result = cursor.callfunc(
            "fun_adjust_Bill", 
            oracledb.NUMBER, 
            [
                adjustment_id, 
                bill_id, 
                datetime.datetime.now(),  # Adjustment Date
                officer_name, 
                officer_designation, 
                original_bill_amount, 
                adjustment_amount, 
                adjustment_reason
            ]
        )

        if result == -1:
            raise HTTPException(status_code=400, detail="error")

        cursor.execute(
            """
            SELECT AdjustmentID, BillID, OfficerName, OfficerDesignation, 
                   OriginalBillAmount, AdjustmentAmount, AdjustmentReason, AdjustmentDate
            FROM BillAdjustments 
            WHERE AdjustmentID = :adjustment_id
        """, {"adjustment_id": adjustment_id})

        adjustment_details = cursor.fetchone()

        if not adjustment_details:
            raise HTTPException(status_code=404, detail="Adjustment error")

        adjustment_info = {
            "adjustment_id": adjustment_details[0],
            "bill_id": adjustment_details[1],
            "officer_name": adjustment_details[2],
            "officer_designation": adjustment_details[3],
            "original_bill_amount": adjustment_details[4],
            "adjustment_amount": adjustment_details[5],
            "adjustment_reason": adjustment_details[6],
            "adjustment_date": adjustment_details[7],
        }

        connection.commit()

        return templates.TemplateResponse("bill_adjustment.html", {"request": request, "adjustment_details": adjustment_info})

    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    finally:
        if cursor:
            cursor.close()

if __name__ == "__main__":
    uvicorn.run(app, host='0.0.0.0', port=8000)