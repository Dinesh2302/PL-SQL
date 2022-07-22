CREATE OR REPLACE FUNCTION TIME_CARD_UPDATE(
  ) RETURNS TRIGGER
AS
  $TIME_CARD$
  DECLARE
    X RECORD;
    Y RECORD;
    Z RECORD;
    V_INTIME VARCHAR(100);
    OUTTIME  VARCHAR(100);
    EMPID    VARCHAR(100);
    TENTRY   DATE;
  BEGIN
    --    INSERT
    --    INTO XX_TEMP_TIMECARD_INOUT_TBL (EMPLOYEE_ID,TIMEENTRYDATE,SHIFTNAME)
    --      VALUES (NEW.EMPLOYEE_ID,NEW.SHIFT_DATE,NEW.SHIFT_NAME);
    --     ---------------------------------------
    --    INSERT
    --    INTO TEMP1
    --      ( SHIFTNAME ) VALUES ( NEW.SHIFT_DATE );
    -------------------------------------------------
    BEGIN
      FOR X IN
      (SELECT EMPLOYEE_ID,
        SHIFT_DATE,
        SHIFT_NAME,
        START_TIME
      FROM XX_TEMP_EMP_SHIFT_DETAILS
      ORDER BY EMPLOYEE_ID,
        SHIFT_DATE
      )
      LOOP
        BEGIN
          --insert into temp1 (shiftname) values (x.shiftname);
          FOR Y IN
          (SELECT A.EMPLOYEE_ID ,
            CAST(A.TIME_ENTRY AS DATE) TIME_ENTRY ,
            MIN(CAST(A.TIME_ENTRY AS TIME)) AS INTIMING
          FROM XX_TIMECARD_LOGIC_TBL A
          WHERE IN_OUT = 'IN'
          GROUP BY A.EMPLOYEE_ID,
            A.TIME_ENTRY
          )
          LOOP
            UPDATE XX_TEMP_TIMECARD_INOUT_TBL
            SET INTIME        = Y.INTIMING
            WHERE EMPLOYEE_ID = Y.EMPLOYEE_ID
            AND Y.TIME_ENTRY  = TIMEENTRYDATE;
          END LOOP;
          ----------------------------------------------------------------------
          FOR Z IN
          (SELECT B.EMPLOYEE_ID ,
            CAST(B.TIME_ENTRY AS DATE) TIME_ENTRY,
            MAX(CAST(B.TIME_ENTRY AS TIME)) AS OUTTIMING
          FROM XX_TIMECARD_LOGIC_TBL B,
            XX_TEMP_EMP_SHIFT_DETAILS AA
          WHERE IN_OUT      = 'OUT'
          AND B.EMPLOYEE_ID = AA.EMPLOYEE_ID
          GROUP BY B.EMPLOYEE_ID,
            B.TIME_ENTRY
          )
          LOOP
            IF CAST(X.START_TIME AS TIME) > '12:00' AND Z.TIME_ENTRY > X.SHIFT_DATE THEN
              UPDATE XX_TEMP_TIMECARD_INOUT_TBL
              SET OUTTIME       = Z.OUTTIMING
              WHERE EMPLOYEE_ID = Z.EMPLOYEE_ID
              AND TIMEENTRYDATE = (Z.TIME_ENTRY - INTERVAL '1 day');
              ------------------------------------------------------------------
            ELSIF CAST(X.START_TIME AS TIME)>'12:00' AND Z.TIME_ENTRY = X.SHIFT_DATE THEN
              UPDATE XX_TEMP_TIMECARD_INOUT_TBL
              SET OUTTIME       = Z.OUTTIMING
              WHERE EMPLOYEE_ID = Z.EMPLOYEE_ID
              AND TIMEENTRYDATE = Z.TIME_ENTRY;
              ------------------------------------------------------------------
            ELSIF CAST(X.START_TIME AS TIME)<'12:00' AND Z.TIME_ENTRY = X.SHIFT_DATE THEN
              UPDATE XX_TEMP_TIMECARD_INOUT_TBL
              SET OUTTIME       = Z.OUTTIMING
              WHERE EMPLOYEE_ID = Z.EMPLOYEE_ID
              AND TIMEENTRYDATE = Z.TIME_ENTRY;
              ------------------------------------------------------------------
            END IF;
          END LOOP;
        END;
      END LOOP;
    END;
    RETURN NEW;
  END;
$TIME_CARD$ LANGUAGE PLPGSQL;