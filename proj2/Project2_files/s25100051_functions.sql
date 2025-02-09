-- Name: Shaheer Humayun
-- Roll No: 25100051
-- Section: S2

-- The file contains the template for the functions to be implemented in the assignment. DO NOT MODIFY THE FUNCTION SIGNATURES. Only need to add your implementation within the function bodies.

----------------------------------------------------------
-- 2.1.1 Function to compute billing days
----------------------------------------------------------

CREATE OR REPLACE FUNCTION fun_compute_BillingDays (
    p_ConnectionID IN VARCHAR2,         
    p_BillingMonth IN NUMBER,           
    p_BillingYear IN NUMBER             
) RETURN NUMBER  
IS
-- varaible declarations
    v_LastReadingCurrentMonth DATE;
    v_LastReadingPreviousMonth DATE;
    v_BillingDays NUMBER;
BEGIN
-- main processing logic
    SELECT MAX(TStamp)
    INTO v_LastReadingCurrentMonth
    FROM MeterReadings
    WHERE ConnectionID = p_ConnectionID
      AND TO_CHAR(TStamp, 'MM') = LPAD(p_BillingMonth, 2, '0')
      AND TO_CHAR(TStamp, 'YYYY') = TO_CHAR(p_BillingYear);

    SELECT MAX(TStamp)
    INTO v_LastReadingPreviousMonth
    FROM MeterReadings
    WHERE ConnectionID = p_ConnectionID
      AND TO_CHAR(TStamp, 'MM') = TO_CHAR(ADD_MONTHS(TO_DATE(p_BillingYear || '-' || p_BillingMonth, 'YYYY-MM'), -1), 'MM') 
      AND TO_CHAR(TStamp, 'YYYY') = TO_CHAR(ADD_MONTHS(TO_DATE(p_BillingYear || '-' || p_BillingMonth, 'YYYY-MM'), -1), 'YYYY'); 

    IF v_LastReadingPreviousMonth IS NULL THEN
        RETURN NULL; 
    END IF;

    v_BillingDays := v_LastReadingCurrentMonth - v_LastReadingPreviousMonth;

    RETURN v_BillingDays;

EXCEPTION
-- exception handling
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No data found for the provided connection.');
        RETURN NULL;  
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RETURN NULL;  
END fun_compute_BillingDays;
/



----------------------------------------------------------
-- 2.1.2 Function to compute Import_PeakUnits
----------------------------------------------------------
CREATE OR REPLACE FUNCTION fun_compute_ImportPeakUnits (
    p_ConnectionID IN VARCHAR2,
    p_BillingMonth IN NUMBER,
    p_BillingYear IN NUMBER
) RETURN NUMBER 
IS
-- varaible declarations

    v_CurrImportPeakReading INT;
    v_PrevImportPeakReading INT;
    v_ImportPeakUnits NUMBER;
    v_PrevMonth NUMBER;
    v_PrevYear NUMBER;
BEGIN
-- main processing logic

    IF p_BillingMonth = 1 THEN
        v_PrevMonth := 12;  
        v_PrevYear := p_BillingYear - 1;  
    ELSE
        v_PrevMonth := p_BillingMonth - 1; 
        v_PrevYear := p_BillingYear;  
    END IF;

    SELECT Import_PeakReading INTO v_CurrImportPeakReading
    FROM MeterReadings
    WHERE ConnectionID = p_ConnectionID
      AND TO_CHAR(TStamp, 'MM') = LPAD(p_BillingMonth, 2, '0')  
      AND TO_CHAR(TStamp, 'YYYY') = TO_CHAR(p_BillingYear)  
      AND TStamp = (
          SELECT MAX(TStamp)
          FROM MeterReadings
          WHERE ConnectionID = p_ConnectionID
            AND TO_CHAR(TStamp, 'MM') = LPAD(p_BillingMonth, 2, '0')
            AND TO_CHAR(TStamp, 'YYYY') = TO_CHAR(p_BillingYear)
      );

    SELECT Import_PeakReading INTO v_PrevImportPeakReading
    FROM MeterReadings
    WHERE ConnectionID = p_ConnectionID
      AND TO_CHAR(TStamp, 'MM') = LPAD(v_PrevMonth, 2, '0')
      AND TO_CHAR(TStamp, 'YYYY') = TO_CHAR(v_PrevYear)  
      AND TStamp = (
          SELECT MAX(TStamp)
          FROM MeterReadings
          WHERE ConnectionID = p_ConnectionID
            AND TO_CHAR(TStamp, 'MM') = LPAD(v_PrevMonth, 2, '0')
            AND TO_CHAR(TStamp, 'YYYY') = TO_CHAR(v_PrevYear)
      );

    v_ImportPeakUnits := v_CurrImportPeakReading - v_PrevImportPeakReading;

    RETURN v_ImportPeakUnits;

EXCEPTION
-- exception handling

    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No data');
        RETURN -1;  
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('error: ' || SQLERRM);
        RETURN -1;  
END fun_compute_ImportPeakUnits;
/

----------------------------------------------------------
-- 2.1.3 Function to compute Import_OffPeakUnits
----------------------------------------------------------
CREATE OR REPLACE FUNCTION fun_compute_ImportOffPeakUnits (
    p_ConnectionID IN VARCHAR2,
    p_BillingMonth IN NUMBER,
    p_BillingYear IN NUMBER
) RETURN NUMBER
IS
-- varaible declarations

    v_CurrOffPeakReading NUMBER;   
    v_PrevOffPeakReading NUMBER;   
    v_ImportOffPeakUnits NUMBER;   
    v_PrevMonth NUMBER;           
    v_PrevYear NUMBER;            
BEGIN
-- main processing logic

    IF p_BillingMonth = 1 THEN
        v_PrevMonth := 12;  
        v_PrevYear := p_BillingYear - 1;  
    ELSE
        v_PrevMonth := p_BillingMonth - 1;  
        v_PrevYear := p_BillingYear;
    END IF;

    SELECT Import_OffPeakReading
    INTO v_CurrOffPeakReading
    FROM MeterReadings
    WHERE ConnectionID = p_ConnectionID
      AND TO_CHAR(TStamp, 'MM') = LPAD(p_BillingMonth, 2, '0') 
      AND TO_CHAR(TStamp, 'YYYY') = TO_CHAR(p_BillingYear)
      AND TStamp = (
          SELECT MAX(TStamp)
          FROM MeterReadings
          WHERE ConnectionID = p_ConnectionID
            AND TO_CHAR(TStamp, 'MM') = LPAD(p_BillingMonth, 2, '0')
            AND TO_CHAR(TStamp, 'YYYY') = TO_CHAR(p_BillingYear)
      );

    SELECT Import_OffPeakReading
    INTO v_PrevOffPeakReading
    FROM MeterReadings
    WHERE ConnectionID = p_ConnectionID
      AND TO_CHAR(TStamp, 'MM') = LPAD(v_PrevMonth, 2, '0') 
      AND TO_CHAR(TStamp, 'YYYY') = TO_CHAR(v_PrevYear) 
      AND TStamp = (
          SELECT MAX(TStamp)
          FROM MeterReadings
          WHERE ConnectionID = p_ConnectionID
            AND TO_CHAR(TStamp, 'MM') = LPAD(v_PrevMonth, 2, '0')
            AND TO_CHAR(TStamp, 'YYYY') = TO_CHAR(v_PrevYear)
      );

    v_ImportOffPeakUnits := v_CurrOffPeakReading - v_PrevOffPeakReading;
    
    RETURN v_ImportOffPeakUnits;

EXCEPTION
-- exception handling

    WHEN NO_DATA_FOUND THEN

        RETURN -1;
    WHEN OTHERS THEN

        RETURN -1;
END fun_compute_ImportOffPeakUnits;
/

----------------------------------------------------------
-- 2.1.4 Function to compute Export_OffPeakUnits
----------------------------------------------------------
CREATE OR REPLACE FUNCTION fun_compute_ExportOffPeakUnits (
    p_ConnectionID IN VARCHAR2,
    p_BillingMonth IN NUMBER,
    p_BillingYear IN NUMBER
) RETURN NUMBER

IS
-- varaible declarations

    v_CurrExportOffPeakReading NUMBER;
    v_PrevExportOffPeakReading NUMBER;
    v_ExportOffPeakUnits NUMBER;
    v_PrevMonth NUMBER;
    v_PrevYear NUMBER;
BEGIN
-- main processing logic

    IF p_BillingMonth = 1 THEN
        v_PrevMonth := 12;
        v_PrevYear := p_BillingYear - 1;
    ELSE
        v_PrevMonth := p_BillingMonth - 1;
        v_PrevYear := p_BillingYear;
    END IF;

    SELECT Export_OffPeakReading
    INTO v_CurrExportOffPeakReading
    FROM MeterReadings
    WHERE ConnectionID = p_ConnectionID
      AND TO_CHAR(TStamp, 'MM') = LPAD(p_BillingMonth, 2, '0')
      AND TO_CHAR(TStamp, 'YYYY') = TO_CHAR(p_BillingYear)
      AND TStamp = (
          SELECT MAX(TStamp)
          FROM MeterReadings
          WHERE ConnectionID = p_ConnectionID
            AND TO_CHAR(TStamp, 'MM') = LPAD(p_BillingMonth, 2, '0')
            AND TO_CHAR(TStamp, 'YYYY') = TO_CHAR(p_BillingYear)
      );

    SELECT Export_OffPeakReading
    INTO v_PrevExportOffPeakReading
    FROM MeterReadings
    WHERE ConnectionID = p_ConnectionID
      AND TO_CHAR(TStamp, 'MM') = LPAD(v_PrevMonth, 2, '0')
      AND TO_CHAR(TStamp, 'YYYY') = TO_CHAR(v_PrevYear)
      AND TStamp = (
          SELECT MAX(TStamp)
          FROM MeterReadings
          WHERE ConnectionID = p_ConnectionID
            AND TO_CHAR(TStamp, 'MM') = LPAD(v_PrevMonth, 2, '0')
            AND TO_CHAR(TStamp, 'YYYY') = TO_CHAR(v_PrevYear)
      );

    v_ExportOffPeakUnits := v_CurrExportOffPeakReading - v_PrevExportOffPeakReading;

    RETURN v_ExportOffPeakUnits;

EXCEPTION
-- exception handling

    WHEN NO_DATA_FOUND THEN
        RETURN -1;
    WHEN OTHERS THEN
        RETURN -1;
END fun_compute_ExportOffPeakUnits;
/


----------------------------------------------------------
-- 2.2.1 Function to compute PeakAmount
----------------------------------------------------------
CREATE OR REPLACE FUNCTION fun_compute_PeakAmount (
    p_ConnectionID IN VARCHAR2,
    p_BillingMonth IN NUMBER,
    p_BillingYear IN NUMBER,
    p_BillIssueDate IN DATE
)
RETURN NUMBER
IS
-- varaible declarations

    days_billed NUMBER;
    peak_consumed_units NUMBER;
    excess_peak_units NUMBER;
    computed_peak_charge NUMBER;
    base_units_threshold NUMBER;
    unit_rate NUMBER;
    base_charge NUMBER;
    scaled_base_units NUMBER;
    scaled_base_charge NUMBER;
    peak_charge_total NUMBER;

BEGIN
-- main processing logic

    days_billed := fun_compute_BillingDays(p_ConnectionID, p_BillingMonth, p_BillingYear);
    
    peak_consumed_units := fun_compute_ImportPeakUnits(p_ConnectionID, p_BillingMonth, p_BillingYear);
    
    SELECT MinUnit, RatePerUnit, MinAmount
    INTO base_units_threshold, unit_rate, base_charge
    FROM Tariff
    WHERE TariffType = 1
      AND StartDate <= p_BillIssueDate
      AND EndDate >= p_BillIssueDate
      AND ConnectionTypeCode = (SELECT ConnectionTypeCode FROM Connections WHERE ConnectionID = p_ConnectionID)
      AND ((peak_consumed_units / (days_billed * 24)) BETWEEN ThresholdLow_perHour AND ThresholdHigh_perHour)
      AND ROWNUM = 1;

    scaled_base_units := base_units_threshold * days_billed / 30;
    scaled_base_charge := base_charge * days_billed / 30;

    excess_peak_units := peak_consumed_units - scaled_base_units;

    computed_peak_charge := (excess_peak_units * unit_rate) + scaled_base_charge;

    peak_charge_total := ROUND(computed_peak_charge, 2);
    
    RETURN peak_charge_total;

EXCEPTION
-- exception handling

    WHEN NO_DATA_FOUND THEN
        RETURN -1;
    WHEN OTHERS THEN
        RETURN -1;
END fun_compute_PeakAmount;
/

----------------------------------------------------------
-- 2.2.2 Function to compute OffPeakAmount
----------------------------------------------------------
CREATE OR REPLACE FUNCTION fun_compute_OffPeakAmount (
    p_ConnectionID IN VARCHAR2,
    p_BillingMonth IN NUMBER,
    p_BillingYear IN NUMBER,
    p_BillIssueDate IN DATE
)
RETURN NUMBER
IS
-- varaible declarations

    days_in_billing_period NUMBER;
    imported_offpeak_units NUMBER;
    exported_offpeak_units NUMBER;
    extra_imported_units_offpeak NUMBER;
    extra_exported_units_offpeak NUMBER;
    import_tariff_units NUMBER;
    export_tariff_units NUMBER;
    import_unit_rate NUMBER;
    export_unit_rate NUMBER;
    import_base_charge NUMBER;
    export_base_charge NUMBER;
    total_offpeak_import_charge NUMBER;
    total_offpeak_export_credit NUMBER;
    net_offpeak_charge NUMBER;

BEGIN
-- main processing logic

    days_in_billing_period := fun_compute_BillingDays(p_ConnectionID, p_BillingMonth, p_BillingYear);
    
    imported_offpeak_units := fun_compute_ImportOffPeakUnits(p_ConnectionID, p_BillingMonth, p_BillingYear);
    exported_offpeak_units := fun_compute_ExportOffPeakUnits(p_ConnectionID, p_BillingMonth, p_BillingYear);
    
    SELECT MinUnit, RatePerUnit, MinAmount
    INTO import_tariff_units, import_unit_rate, import_base_charge
    FROM Tariff
    WHERE TariffType = 2 
      AND StartDate <= p_BillIssueDate
      AND EndDate >= p_BillIssueDate
      AND ConnectionTypeCode = (SELECT ConnectionTypeCode FROM Connections WHERE ConnectionID = p_ConnectionID)
      AND ((imported_offpeak_units / (days_in_billing_period * 24)) BETWEEN ThresholdLow_perHour AND ThresholdHigh_perHour)
      AND ROWNUM = 1;

    SELECT MinUnit, RatePerUnit, MinAmount
    INTO export_tariff_units, export_unit_rate, export_base_charge
    FROM Tariff
    WHERE TariffType = 2 
      AND StartDate <= p_BillIssueDate
      AND EndDate >= p_BillIssueDate
      AND ConnectionTypeCode = (SELECT ConnectionTypeCode FROM Connections WHERE ConnectionID = p_ConnectionID)
      AND ((exported_offpeak_units / (days_in_billing_period * 24)) BETWEEN ThresholdLow_perHour AND ThresholdHigh_perHour)
      AND ROWNUM = 1;

    extra_imported_units_offpeak := imported_offpeak_units - (import_tariff_units * days_in_billing_period / 30);
    extra_exported_units_offpeak := exported_offpeak_units - (export_tariff_units * days_in_billing_period / 30);

    total_offpeak_import_charge := (extra_imported_units_offpeak * import_unit_rate) + (import_base_charge * days_in_billing_period / 30);
    total_offpeak_export_credit := (extra_exported_units_offpeak * export_unit_rate) + (export_base_charge * days_in_billing_period / 30);

    net_offpeak_charge := total_offpeak_import_charge - total_offpeak_export_credit;

    RETURN ROUND(net_offpeak_charge, 2);

EXCEPTION
-- exception handling

    WHEN NO_DATA_FOUND THEN
        RETURN -1;
    WHEN OTHERS THEN
        RETURN -1;
END fun_compute_OffPeakAmount;
/
----------------------------------------------------------
-- 2.3.1 Function to compute TaxAmount
----------------------------------------------------------
CREATE OR REPLACE FUNCTION fun_compute_TaxAmount (
    p_ConnectionID  IN VARCHAR2,
    p_BillingMonth  IN NUMBER,
    p_BillingYear   IN NUMBER,
    p_BillIssueDate IN DATE,
    p_PeakAmount    IN NUMBER,
    p_OffPeakAmount IN NUMBER
) RETURN NUMBER
IS
-- varaible declarations

    total_tax_rate NUMBER := 0;
    total_tax_amount NUMBER := 0;
    base_amount NUMBER;

BEGIN
-- main processing logic

    base_amount := p_PeakAmount + p_OffPeakAmount;
    
    FOR tax_rate IN (
        SELECT Rate
        FROM TaxRates
        WHERE ConnectionTypeCode = (SELECT ConnectionTypeCode FROM Connections WHERE ConnectionID = p_ConnectionID)
          AND StartDate <= p_BillIssueDate
          AND EndDate >= p_BillIssueDate
    ) LOOP

        total_tax_amount := total_tax_amount + (base_amount * tax_rate.Rate);
    END LOOP;


    RETURN ROUND(total_tax_amount, 2);

EXCEPTION
-- exception handling

    WHEN NO_DATA_FOUND THEN
        RETURN -1;
    WHEN OTHERS THEN
        RETURN -1;
END fun_compute_TaxAmount;
/
----------------------------------------------------------
-- 2.3.2 Function to compute FixedFee Amount
----------------------------------------------------------
CREATE OR REPLACE FUNCTION fun_compute_FixedFee (
    p_ConnectionID IN VARCHAR2,
    p_BillingMonth IN NUMBER,
    p_BillingYear IN NUMBER,
    p_BillIssueDate IN DATE
) RETURN NUMBER
IS
-- varaible declarations

    total_fixed_fee NUMBER := 0;
    fee_record FixedCharges.FixedFee%TYPE;
BEGIN
-- main processing logic

    FOR fee_record IN (
        SELECT FixedFee
        FROM FixedCharges fc
        JOIN Connections c ON fc.ConnectionTypeCode = c.ConnectionTypeCode
        WHERE c.ConnectionID = p_ConnectionID
          AND fc.StartDate <= p_BillIssueDate
          AND fc.EndDate >= p_BillIssueDate
    ) LOOP
        total_fixed_fee := total_fixed_fee + fee_record.FixedFee;
    END LOOP;

    RETURN ROUND(total_fixed_fee, 2);

EXCEPTION
-- exception handling

    WHEN NO_DATA_FOUND THEN
        RETURN -1;  
    WHEN OTHERS THEN
        RETURN -1;  
END fun_compute_FixedFee;
/

----------------------------------------------------------
-- 2.3.3 Function to compute Arrears
----------------------------------------------------------
CREATE OR REPLACE FUNCTION fun_compute_Arrears (
    p_ConnectionID IN VARCHAR2,
    p_BillingMonth IN NUMBER,
    p_BillingYear IN NUMBER,
    p_BillIssueDate IN DATE
) RETURN NUMBER
IS
-- varaible declarations

    v_previous_bill_amount DECIMAL(10, 2);
    v_due_date DATE;
    v_total_paid DECIMAL(10, 2) := 0;
    v_arrears DECIMAL(10, 2);
BEGIN
-- main processing logic

    BEGIN
        SELECT TotalAmount_AfterDueDate, DueDate
        INTO v_previous_bill_amount, v_due_date
        FROM Bill
        WHERE ConnectionID = p_ConnectionID
          AND BillingMonth = p_BillingMonth - 1
          AND BillingYear = p_BillingYear;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN

            RETURN 0;
    END;


    BEGIN
        SELECT NVL(SUM(AmountPaid), 0)
        INTO v_total_paid
        FROM PaymentDetails
        WHERE BillID = (SELECT BillID 
                        FROM Bill 
                        WHERE ConnectionID = p_ConnectionID 
                          AND BillingMonth = p_BillingMonth - 1 
                          AND BillingYear = p_BillingYear)
        AND PaymentStatus = 'Fully Paid';  
    EXCEPTION
        WHEN NO_DATA_FOUND THEN

            v_total_paid := 0;
    END;


    IF v_total_paid = 0 THEN

        v_arrears := v_previous_bill_amount;
    ELSE

        v_arrears := v_previous_bill_amount - v_total_paid;
    END IF;

    -- DBMS_OUTPUT.PUT_LINE('Previous Bill Amount: ' || v_previous_bill_amount);
    -- DBMS_OUTPUT.PUT_LINE('Total Paid: ' || v_total_paid);
    -- DBMS_OUTPUT.PUT_LINE('Arrears: ' || v_arrears);

    RETURN v_arrears;
END fun_compute_Arrears;
/


----------------------------------------------------------
-- 2.3.4 Function to compute SubsidyAmount
----------------------------------------------------------
CREATE OR REPLACE FUNCTION fun_compute_SubsidyAmount (
    p_ConnectionID      IN VARCHAR2,
    p_BillingMonth      IN NUMBER,
    p_BillingYear       IN NUMBER,
    p_BillIssueDate     IN DATE,
    p_ImportPeakUnits   IN NUMBER,
    p_ImportOffPeakUnits IN NUMBER
) RETURN NUMBER
IS
-- varaible declarations

    v_BillingDays           NUMBER;
    v_UnitPerHourSubsidy    NUMBER;
    v_SubsidyAmount         NUMBER := 0;
    v_RatePerUnit           NUMBER;
    v_ConnectionTypeCode    INT;
BEGIN
-- main processing logic

    SELECT ConnectionTypeCode
    INTO v_ConnectionTypeCode
    FROM Connections
    WHERE ConnectionID = p_ConnectionID;

    SELECT fun_compute_BillingDays(p_ConnectionID, p_BillingMonth, p_BillingYear) 
    INTO v_BillingDays
    FROM dual;
    
    v_UnitPerHourSubsidy := (p_ImportPeakUnits + p_ImportOffPeakUnits) / (v_BillingDays * 24);

    FOR subsidy_rec IN (
        SELECT RatePerUnit
        FROM Subsidy
        WHERE ConnectionTypeCode = v_ConnectionTypeCode 
        AND p_BillIssueDate BETWEEN StartDate AND EndDate
    ) LOOP

        v_SubsidyAmount := v_SubsidyAmount + (v_UnitPerHourSubsidy * 24 * v_BillingDays) * subsidy_rec.RatePerUnit;
    END LOOP;

    RETURN ROUND(v_SubsidyAmount, 2);

EXCEPTION
-- exception handling

    WHEN OTHERS THEN

        RETURN -1;
END fun_compute_SubsidyAmount;
/
----------------------------------------------------------
-- 2.4.1 Function to generate Bill by inserting records in the Bill Table
----------------------------------------------------------
CREATE OR REPLACE FUNCTION fun_generate_Bill (
  p_BillID IN NUMBER,
  p_ConnectionID IN VARCHAR2,
  p_BillingMonth IN NUMBER,
  p_BillingYear IN NUMBER,
  p_BillIssueDate IN DATE
) RETURN NUMBER
IS
-- varaible declarations

  v_Import_PeakUnits INT;
  v_Import_OffPeakUnits INT;
  v_Export_PeakUnits INT;
  v_Export_OffPeakUnits INT;
  v_Net_PeakUnits INT;
  v_Net_OffPeakUnits INT;
  v_PeakAmount DECIMAL(10, 2);
  v_OffPeakAmount DECIMAL(10, 2);
  v_FixedFee DECIMAL(10, 2);
  v_TaxAmount DECIMAL(10, 2);
  v_Arrears DECIMAL(10, 2);
  v_AdjustmentAmount DECIMAL(10, 2) := 0; 
  v_SubsidyAmount DECIMAL(10, 2);
  v_TotalAmount_BeforeDueDate DECIMAL(10, 2);
  v_TotalAmount_AfterDueDate DECIMAL(10, 2);
  v_DueDate DATE;
BEGIN
-- main processing logic

  v_Import_PeakUnits := fun_compute_ImportPeakUnits(p_ConnectionID, p_BillingMonth, p_BillingYear);
  v_Import_OffPeakUnits := fun_compute_ImportOffPeakUnits(p_ConnectionID, p_BillingMonth, p_BillingYear);
  v_Export_OffPeakUnits := fun_compute_ExportOffPeakUnits(p_ConnectionID, p_BillingMonth, p_BillingYear);
  v_PeakAmount := fun_compute_PeakAmount(p_ConnectionID, p_BillingMonth, p_BillingYear, p_BillIssueDate);
  v_OffPeakAmount := fun_compute_OffPeakAmount(p_ConnectionID, p_BillingMonth, p_BillingYear, p_BillIssueDate);
  v_TaxAmount := fun_compute_TaxAmount(p_ConnectionID, p_BillingMonth, p_BillingYear, p_BillIssueDate, v_PeakAmount, v_OffPeakAmount);
  v_FixedFee := fun_compute_FixedFee(p_ConnectionID, p_BillingMonth, p_BillingYear, p_BillIssueDate);
  v_Arrears := fun_compute_Arrears(p_ConnectionID, p_BillingMonth, p_BillingYear, p_BillIssueDate);
  v_SubsidyAmount := fun_compute_SubsidyAmount(p_ConnectionID, p_BillingMonth, p_BillingYear, p_BillIssueDate, v_Import_PeakUnits, v_Import_OffPeakUnits);

  v_Net_PeakUnits := v_Import_PeakUnits - v_Export_PeakUnits;
  v_Net_OffPeakUnits := v_Import_OffPeakUnits - v_Export_OffPeakUnits;

  v_TotalAmount_BeforeDueDate := (v_PeakAmount + v_OffPeakAmount + v_TaxAmount + v_FixedFee) - (v_SubsidyAmount + v_AdjustmentAmount) + v_Arrears;
  v_DueDate := p_BillIssueDate + 10;
  v_TotalAmount_AfterDueDate := v_TotalAmount_BeforeDueDate * 1.10;

  INSERT INTO Bill (
    BillID, ConnectionID, BillingMonth, BillingYear, BillIssueDate,
    Import_PeakUnits, Import_OffPeakUnits, Export_PeakUnits, Export_OffPeakUnits,
    Net_PeakUnits, Net_OffPeakUnits, PeakAmount, OffPeakAmount, FixedFee,
    TaxAmount, Arrears, AdjustmentAmount, SubsidyAmount, DueDate,
    TotalAmount_BeforeDueDate, TotalAmount_AfterDueDate) 
  VALUES (
    p_BillID, p_ConnectionID, p_BillingMonth, p_BillingYear, p_BillIssueDate,
    v_Import_PeakUnits, v_Import_OffPeakUnits, v_Export_PeakUnits, v_Export_OffPeakUnits,
    v_Net_PeakUnits, v_Net_OffPeakUnits, v_PeakAmount, v_OffPeakAmount, v_FixedFee,
    v_TaxAmount, v_Arrears, v_AdjustmentAmount, v_SubsidyAmount, v_DueDate,
    v_TotalAmount_BeforeDueDate, v_TotalAmount_AfterDueDate);

  RETURN 1;

EXCEPTION
-- exception handling

  WHEN OTHERS THEN

    RETURN -1;
END fun_generate_Bill;
/

----------------------------------------------------------
-- 2.4.2 Function for generating monthly bills of all consumers
----------------------------------------------------------
CREATE OR REPLACE FUNCTION fun_batch_Billing (
    p_BillingMonth  IN NUMBER,
    p_BillingYear   IN NUMBER,
    p_BillIssueDate IN DATE
) RETURN NUMBER 
IS
-- varaible declarations

    v_BillingResult NUMBER;
    v_SuccessfulBills NUMBER := 0;
BEGIN
-- main processing logic

    FOR rec IN (
        SELECT BillID, ConnectionID
        FROM Bill
        WHERE BillingMonth = p_BillingMonth
        AND BillingYear = p_BillingYear
        AND ConnectionID IN (
            SELECT ConnectionID
            FROM Connections
            WHERE status = 'Active'
        )
    )
     LOOP
        v_BillingResult := fun_Generate_Bill(rec.BillID, rec.ConnectionID, p_BillingMonth, p_BillingYear, p_BillIssueDate);

        v_SuccessfulBills := v_SuccessfulBills + 1;
    END LOOP;

    RETURN v_SuccessfulBills;

EXCEPTION
-- exception handling

    WHEN OTHERS THEN
        RETURN -1; 
END fun_batch_Billing;
/


----------------------------------------------------------
-- 3.1.1 Function to process and record Payment
----------------------------------------------------------
CREATE OR REPLACE FUNCTION fun_process_Payment (
  p_BillID IN NUMBER,
  p_PaymentDate IN DATE,
  p_PaymentMethodID IN NUMBER,
  p_AmountPaid IN NUMBER
) RETURN NUMBER 
IS
-- varaible declarations

  v_TotalAmountBeforeDueDate NUMBER := 0;
  v_TotalAmountAfterDueDate NUMBER := 0;
  v_AmountPaidToDate NUMBER := 0;
  v_RemainingBalance NUMBER := 0;
  v_PaymentStatus VARCHAR2(50);
  v_NewArrears NUMBER := 0;
  v_DueDate DATE;
BEGIN
-- main processing logic

  SELECT TotalAmount_BeforeDueDate, TotalAmount_AfterDueDate, DueDate
  INTO v_TotalAmountBeforeDueDate, v_TotalAmountAfterDueDate, v_DueDate
  FROM Bill
  WHERE BillID = p_BillID;

  SELECT NVL(SUM(AmountPaid), 0)
  INTO v_AmountPaidToDate
  FROM PaymentDetails
  WHERE BillID = p_BillID;

  v_AmountPaidToDate := v_AmountPaidToDate + p_AmountPaid;

  IF p_PaymentDate <= v_DueDate THEN
    v_RemainingBalance := v_TotalAmountBeforeDueDate - v_AmountPaidToDate;
  ELSE
    v_RemainingBalance := v_TotalAmountAfterDueDate - v_AmountPaidToDate;
  END IF;

  IF v_RemainingBalance <= 0 THEN
    v_PaymentStatus := 'Fully Paid';
    v_NewArrears := 0;
  ELSE
    v_PaymentStatus := 'Partially Paid';
    v_NewArrears := v_RemainingBalance;
  END IF;

  INSERT INTO PaymentDetails (
    BillID, PaymentDate, PaymentStatus, PaymentMethodID, AmountPaid
  ) VALUES (
    p_BillID, p_PaymentDate, v_PaymentStatus, p_PaymentMethodID, p_AmountPaid
  );

  UPDATE Bill
  SET Arrears = v_NewArrears
  WHERE BillID = p_BillID;

  RETURN 1;

EXCEPTION
-- exception handling

  WHEN NO_DATA_FOUND THEN

    RETURN -1;
  WHEN OTHERS THEN

    RETURN -1;
END fun_process_Payment;
/



----------------------------------------------------------
-- 4.1.1 Function to make Bill adjustment
----------------------------------------------------------
CREATE OR REPLACE FUNCTION fun_adjust_Bill (
    p_AdjustmentID       IN NUMBER,
    p_BillID             IN NUMBER,
    p_AdjustmentDate     IN DATE,
    p_OfficerName        IN VARCHAR2,
    p_OfficerDesignation IN VARCHAR2,
    p_OriginalBillAmount IN NUMBER,
    p_AdjustmentAmount   IN NUMBER,
    p_AdjustmentReason   IN VARCHAR2
) RETURN NUMBER
IS
-- varaible declarations

    v_OriginalBillAmount   DECIMAL(10, 2);
    v_TotalAmountBeforeDueDate DECIMAL(10, 2);
    v_TotalAmountAfterDueDate DECIMAL(10, 2);
    v_NewTotalAmountBeforeDueDate DECIMAL(10, 2);
    v_NewTotalAmountAfterDueDate DECIMAL(10, 2);
BEGIN
-- main processing logic

    SELECT TotalAmount_BeforeDueDate, TotalAmount_AfterDueDate
    INTO v_TotalAmountBeforeDueDate, v_TotalAmountAfterDueDate
    FROM Bill
    WHERE BillID = p_BillID;
    
    IF p_AdjustmentAmount <= 0 THEN
        RETURN -1; 
    END IF;

    v_NewTotalAmountBeforeDueDate := v_TotalAmountBeforeDueDate - p_AdjustmentAmount;
    v_NewTotalAmountAfterDueDate := v_TotalAmountAfterDueDate - p_AdjustmentAmount;

    INSERT INTO BillAdjustments (
        AdjustmentID, 
        BillID, 
        AdjustmentAmount, 
        AdjustmentReason, 
        AdjustmentDate, 
        OfficerName, 
        OfficerDesignation, 
        OriginalBillAmount
    ) 
    VALUES (
        p_AdjustmentID, 
        p_BillID, 
        p_AdjustmentAmount, 
        p_AdjustmentReason, 
        p_AdjustmentDate, 
        p_OfficerName, 
        p_OfficerDesignation, 
        p_OriginalBillAmount
    );

    UPDATE Bill
    SET 
        TotalAmount_BeforeDueDate = v_NewTotalAmountBeforeDueDate,
        TotalAmount_AfterDueDate = v_NewTotalAmountAfterDueDate,
        AdjustmentAmount = p_AdjustmentAmount
    WHERE BillID = p_BillID;

    RETURN 1;

EXCEPTION
-- exception handling

    WHEN NO_DATA_FOUND THEN

        RETURN -1;
    WHEN OTHERS THEN

        RETURN -1;
END fun_adjust_Bill;
/
