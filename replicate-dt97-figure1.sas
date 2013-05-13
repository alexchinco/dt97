;/*************************************************************************************
    @title:  REPLICATE DANIEL AND TITMAN (1997) FIGURE 1
    -----------------------------------------------------------------------------------    
    @author: Alex Chinco
    @date:   10/05/2013
    -----------------------------------------------------------------------------------    
    @desc:   This program replicates Figure 1 in Daniel and Titman (1997) showing the
             pre-formation period returns of the HML portfolio.
**************************************************************************************/

LIBNAME comp  '/wrds/comp/sasdata/naa';
LIBNAME crsp  '/wrds/crsp/sasdata/a_stock';
LIBNAME cc    '/wrds/crsp/sasdata/a_ccm';
LIBNAME ff    '/wrds/ff/sasdata';

%LET startDate = '01JUN1961'd; * Need 2 years of pre-sample data.;
%LET endDate   = '31DEC1993'd;












;/*************************************************************************************
    @section: COMPUTE BOOK EQUITY
    -----------------------------------------------------------------------------------    
    @desc:    This section computes the book equity value of firms in the COMPUSTAT
              database using the procedure given in Fama and French (JF 1993) on a yearly
              basis:

              Book Equity = Common Equity + Deferred Taxes - Preferred Stock

              To compute the Preferred Stock (PS) value, I first try to use the redemption
              value; then, if that variable is empty, I try to use the liquidation value;
              finally, if that variable is empty, I use the par value. I count the number
              years a company is in the COMPUSTAT database since companies with less than
              2 years of data likely have backfilled values.
    -----------------------------------------------------------------------------------    
    @data:    annualBookEquityData
                                            book             compustat
              Obs    gvkey     datadate    Equity    year      Years

                1    001000    19681231     2.571    1968        1    
                2    001000    19691231    10.210    1969        2    
                3    001000    19701231    10.544    1970        3    
                4    001000    19711231     8.381    1971        4    
                5    001000    19721231     7.309    1972        5    
                6    001000    19731231     8.798    1973        6    
                7    001000    19741231     7.865    1974        7    
                8    001002    19681231     5.972    1968        1    
                9    001002    19691231     6.533    1969        2    
               10    001002    19701231     7.053    1970        3    
               11    001002    19711231     7.878    1971        4    
               12    001002    19721231     8.667    1972        5    
               13    001004    19690531     4.931    1969        1    
               14    001004    19700531     5.419    1970        2    
               15    001004    19710531     5.930    1971        3    
**************************************************************************************/

%LET vars = at pstkl txditc pstkrv ceq pstk;

DATA annualBookEquityData;
    SET comp.funda (KEEP = gvkey datadate &vars indfmt datafmt popsrc consol);
    BY  gvkey datadate;
    WHERE (indfmt   = 'INDL')      AND
          (datafmt  = 'STD')       AND
          (popsrc   = 'D')         AND
          (consol   = 'C')         AND
          (dataDate >= &startDate) AND
          (dataDate <= &endDate);
    IF MISSING(txditc) THEN
        DO;
        txditc = 0;
        END;
    commonEquity   = ceq;
    deferredTaxes  = txditc;
    preferredStock = COALESCE(pstkrv, pstkl, pstk, 0);
    bookEquity     = commonEquity + deferredTaxes - preferredStock;  
    year           = YEAR(datadate); 
    DROP indfmt datafmt popsrc consol commonEquity deferredTaxes preferredStock &vars;   
    RETAIN compustatYears;
    IF first.gvkey THEN
        DO;
        compustatYears = 1;
        END;
    ELSE
        DO;
        compustatYears = compustatYears + 1;
        END;
RUN;

PROC SORT
    DATA = annualBookEquityData;
    BY gvkey dataDate;
RUN;

PROC PRINT
    DATA = annualBookEquityData(obs = 15);
    TITLE 'First 15 observations of annualBookEquityData.'; 
RUN;












;/*************************************************************************************
    @section: COMPUTE MARKET EQUITY
    -----------------------------------------------------------------------------------    
    @desc:    This section computes the market equity value of firms in the CRSP database
              on a monthly basis:

              Market Equity = abs(Price) * Shares Outstanding
    
              First, I create a CRSP dataset with monthly stock file and event file variables
              names marketEquityData which is sorted by date and permno and contains
              historical returns as well as historical share codes and exchange codes. I
              then use this data to compute the market equity of each firm as well as a
              monthly delisting adjusted return.

              There are cases when the same firm (permco) has >1 security (permno) at same
              date. e.g., think of a firm with 2 share classes. I sum the market equity
              values for each of these permnos and assign the resulting aggregate value to
              the permno with the largest market equity.

              Within each fiscal year, I value weight firms' market equity by its ex dividend
              return:
    
              Market Equity (t) = Market Equity (t-1) * (1 + RETX t-1)

              and create files with December and June market equity calculations.
    -----------------------------------------------------------------------------------    
    @data:    stockReturnData
                                                          portfolio
               Obs        DATE      PERMNO     retAdj       Weight

                 1    19680628       10006     0.29223          .  
                 2    19680730       10006     0.03942    339990.75
                 3    19680830       10006    -0.10100    353392.88
                 4    19680930       10006    -0.05830    314597.25
                 5    19681031       10006     0.04762    296257.50
                 6    19681129       10006     0.10182    310365.00
                 7    19681231       10006     0.04375    338580.00
                 8    19690131       10006     0.03792    353392.88
                 9    19690228       10006    -0.11962    366795.00
                10    19690328       10006     0.01987    319534.88
                11    19690430       10006    -0.15368    325883.25
                12    19690529       10006     0.10435    275801.63
                13    19690630       10006    -0.13349    301195.13
                14    19690731       10006    -0.08108    260896.25
                15    19690829       10006     0.07294    239742.50
    -----------------------------------------------------------------------------------    
    @data:    decemberMarketEquityData
                                              december
                                               Market
              Obs        DATE      PERMNO      Equity

                1    19681231       10006    338580.00
                2    19691231       10006    279934.63
                3    19701231       10006    252434.75
                4    19711231       10006    274384.25
                5    19721229       10006    271454.50
                6    19731231       10006    221437.00
                7    19741231       10006    215831.00
                8    19681231       10014     43733.25
                9    19691231       10014     29790.25
               10    19701231       10014     16962.00
               11    19711231       10014     15021.50
               12    19721229       10014     16859.50
               13    19731231       10014     10237.50
               14    19741231       10014      6142.50
               15    19721229       10023      6142.50
    -----------------------------------------------------------------------------------    
    @data:    annualMarketEquityData
                                                                     december
                                                         market       Market
              Obs        DATE      PERMNO    EXCHCD      Equity       Equity

                1    19690630       10006       1      301195.13    338580.00
                2    19700630       10006       1      217178.50    279934.63
                3    19710630       10006       1      313780.63    252434.75
                4    19720630       10006       1      249823.00    274384.25
                5    19730629       10006       1      246268.00    271454.50
                6    19740628       10006       1      235452.00    221437.00
                7    19690630       10014       1       49476.00     43733.25
                8    19700630       10014       1       20031.37     29790.25
                9    19710630       10014       1       15934.00     16962.00
               10    19720630       10014       1       23687.75     15021.50
               11    19730629       10014       1       10236.13     16859.50
               12    19740628       10014       1        8190.00     10237.50
               13    19730629       10023       3        4005.98      6142.50
               14    19730629       10050       3      145353.89          .  
               15    19740628       10050       3        9000.00      7875.00
**************************************************************************************/

%LET eventFileVars = ticker ncusip shrcd exchcd;
%LET stockFileVars = prc ret retx shrout cfacpr cfacshr;

%INCLUDE '/wrds/crsp/samples/crspmerge.sas';
%CRSPMERGE(S       = m,
           START   = &startDate,
           END     = &endDate,
           SFVARS  = &stockFileVars,
           SEVARS  = &eventFileVars,
           FILTERS = exchcd in (1,2,3)
           );

PROC SQL;
    CREATE TABLE marketEquityData AS
        SELECT   a.*,
                 b.dlret,
                 (SUM(1, ret) * SUM(1, dlret) - 1) AS retAdj,
                 ABS(a.prc * a.shrout) AS marketEquityNonUnique
        FROM     crsp_m AS a LEFT JOIN
                 crsp.msedelist (WHERE = (MISSING(dlret) = 0)) as b
        ON       (a.permno = b.permno) AND 
                 (INTNX('month', a.date, 0, 'E') = INTNX('month', b.dlstdt, 0, 'E'))
        ORDER BY date,
                 permco,
                 marketEquityNonUnique;
QUIT;

DATA marketEquityData (DROP = marketEquityNonUnique);
    SET    marketEquityData;
    BY     date
           permco
           marketEquityNonUnique;
    RETAIN marketEquity;
    IF (first.permco AND last.permco) THEN
        DO;
        marketEquity = marketEquityNonUnique;
        OUTPUT;
        END;
    ELSE
        DO;
        IF (first.permco) THEN
            DO;
            marketEquity = marketEquityNonUnique;
            END;
        ELSE
            DO;
            marketEquity = SUM(marketEquityNonUnique, marketEquity);
            END;
        IF (last.permco) THEN
            DO;
            OUTPUT;
            END;
        END;
    IF exchcd IN (1,2,3);
    IF shrcd  IN (10,11);
    KEEP permno
         date
         exchcd
         marketEquity
         retx
         retAdj;
RUN;

PROC SORT
    DATA = marketEquityData;
    BY permno date;
RUN;

DATA marketEquityData        (KEEP = permno
                                     date
                                     retAdj
                                     portfolioWeight
                                     exchcd)
    decemberMarketEquityData (KEEP = permno
                                     date
                                     portfolioWeight
                                     RENAME = (portfolioWeight = decemberMarketEquity)); 
    SET    marketEquityData;
    BY     permno date;
    RETAIN portfolioWeight cumRetx baseMarketEquity;
    lagPermno       = LAG(permno);
    lagMarketEquity = LAG(marketEquity);
    IF (MONTH(date) = 7) THEN
        DO;
        portfolioWeight  = lagMarketEquity;
        baseMarketEquity = lagMarketEquity; 
        cumRetx          = SUM(1, retx);
        END;
    ELSE
        DO;
        IF (lagMarketEquity > 0) THEN
            DO;
            portfolioWeight = cumRetx * baseMarketEquity;
            END;
        ELSE
            DO;
            portfolioWeight = .;
            END;
        cumRetx = cumRetx * SUM(1, retx);
        END;
    OUTPUT marketEquityData;
    IF ((MONTH(date) = 12) AND (marketEquity > 0)) THEN
        DO;
        OUTPUT decemberMarketEquityData;
        END;
RUN;

DATA stockReturnData;
    SET marketEquityData;
    KEEP permno date retAdj portfolioWeight;
RUN;

PROC SORT
    DATA = stockReturnData;
    BY permno date;
RUN;

PROC PRINT
    DATA = stockReturnData(obs = 15);
    TITLE 'First 15 observations of stockReturnData.'; 
RUN;

PROC SORT
    DATA = decemberMarketEquityData;
    BY permno date;
RUN;

PROC PRINT
    DATA = decemberMarketEquityData(obs = 15);
    TITLE 'First 15 observations of decemberMarketEquityData.'; 
RUN;

PROC SQL;
    CREATE TABLE annualMarketEquityData AS
        SELECT a.date,
               a.permno,
               a.exchcd,
               a.portfolioWeight AS marketEquity,
               b.decemberMarketEquity
        FROM   marketEquityData(WHERE = (MONTH(date) = 6)) AS a,
               decemberMarketEquityData                    AS b
        WHERE  (a.permno = b.permno) AND
               (INTCK('month', b.date, a.date) = 6);
QUIT;

PROC SORT
    DATA = annualMarketEquityData;
    BY permno date;
RUN;

PROC PRINT
    DATA = annualMarketEquityData(obs = 15);
    TITLE 'First 15 observations of annualMarketEquityData.'; 
RUN;













;/*************************************************************************************
    @section: MERGE BOOK EQUITY AND MARKET EQUITY DATA
    -----------------------------------------------------------------------------------    
    @desc:    This section links the book equity data from COMPUSTAT and the market
              equity data from CRSP. First, I add a permno to each observation in the
              COMPUSTAT sample and remove duplicate observations from the COMPUSTAT
              data which come from 2 sources:
              1) Different gvkey for the same (permno,date) pair. e.g., from secondary
                 matches in the CRSP-to-COMPUSTAT merge. I use the linkprim='P' rule to
                 select just one (gvkey,permno,date) tuple.
              2) Change of fiscal year end w/in calendar year. As a result, there are
                  more than one annual record for accounting data. I select the last
                  annual record in a given calendar year.
    
              I merge CRSP-to-COMPUSTAT at June of every calendar year and match fiscal
              year covering t-1 with the calendar date June t.
    -----------------------------------------------------------------------------------    
    @data:    linkedAnnualBookEquityData
                                          book           compustat
              Obs   gvkey    datadate    Equity   year     Years     permno   linkprim

                1   001010   19691231   228.007   1969       2        10006      P    
                2   001010   19701231   240.612   1970       3        10006      P    
                3   001010   19711231   253.482   1971       4        10006      P    
                4   001010   19721231   270.345   1972       5        10006      P    
                5   001010   19731231   294.894   1973       6        10006      P    
                6   001010   19741231   325.948   1974       7        10006      P    
                7   001031   19690331    22.296   1969       1        10014      P    
                8   001031   19700331    23.650   1970       2        10014      P    
                9   001031   19710331    20.443   1971       3        10014      P    
               10   001031   19720331    21.413   1972       4        10014      P    
               11   001031   19730331    23.384   1973       5        10014      P    
               12   001031   19740331    20.603   1974       6        10014      P    
               13   001098   19681231    64.802   1968       1        10057      C    
               14   001098   19690930    67.241   1969       2        10057      C    
               15   001098   19700930    67.977   1970       3        10057      C    
    -----------------------------------------------------------------------------------    
    @data:    annualRankingData
                                                     market      book     bookTo   compustat
              Obs       DATE     PERMNO   EXCHCD     Equity     Equity    Market     Years

                1   19700630      10006      1     217178.50   228.007   0.81450       2    
                2   19710630      10006      1     313780.63   240.612   0.95317       3    
                3   19720630      10006      1     249823.00   253.482   0.92382       4    
                4   19730629      10006      1     246268.00   270.345   0.99591       5    
                5   19740628      10006      1     235452.00   294.894   1.33173       6    
                6   19700630      10014      1      20031.37    22.296   0.74843       1    
                7   19710630      10014      1      15934.00    23.650   1.39429       2    
                8   19720630      10014      1      23687.75    20.443   1.36092       3    
                9   19730629      10014      1      10236.13    21.413   1.27009       4    
               10   19740628      10014      1       8190.00    23.384   2.28415       5    
               11   19690630      10057      1      51104.25    64.802   1.18547       1    
               12   19700630      10057      1      34646.00    67.241   1.47458       2    
               13   19710630      10057      1      51065.50    67.977   1.39707       3    
               14   19720630      10057      1      61952.25    64.568   1.43028       4    
               15   19730629      10057      1      49972.00    64.991   0.97307       5    
**************************************************************************************/

PROC SQL;
    CREATE TABLE linkedAnnualBookEquityData AS
        SELECT a.*,
               b.lpermno AS permno,
               b.linkprim	 
        FROM   annualBookEquityData AS a,
               cc.ccmxpf_linktable  AS b
        WHERE  (a.gvkey = b.gvkey) AND
               (SUBSTR(b.linktype, 1, 1) = 'L') AND
               ((INTNX('month', INTNX('year', a.datadate, 0, 'E'), 6, 'E') >= b.linkdt) OR MISSING(b.linkdt)) AND
               ((b.linkenddt >= INTNX('month', INTNX('year', a.datadate, 0, 'E'), 6,'E')) OR MISSING(b.linkenddt));
QUIT;
    
PROC SORT
    DATA = linkedAnnualBookEquityData
    OUT  = linkedAnnualBookEquityData;
    BY datadate
       permno
       descending
       linkprim
       gvkey;
RUN;

DATA linkedAnnualBookEquityData;
    SET linkedAnnualBookEquityData;
    BY datadate
       permno
       descending
       linkprim
       gvkey;
    IF (first.permno);
RUN;

PROC SORT
    DATA = linkedAnnualBookEquityData
    NODUPKEY;
    BY datadate
       permno;
RUN; 
        
PROC SORT
    DATA = linkedAnnualBookEquityData;
    BY permno
       year
       datadate;
RUN;

DATA linkedAnnualBookEquityData;
    SET linkedAnnualBookEquityData;
    BY permno
       year
       datadate;
    IF (last.year = 1);
run;

PROC SORT
    DATA = linkedAnnualBookEquityData
    NODUPKEY;
    BY permno
       datadate;
RUN;

PROC SORT
    DATA = linkedAnnualBookEquityData;
    BY permno datadate;
RUN;

PROC PRINT
    DATA = linkedAnnualBookEquityData(obs = 15);
    TITLE 'First 15 observations of linkedAnnualBookEquityData.'; 
RUN;

PROC SQL;
    CREATE TABLE annualRankingData AS        
        SELECT   a.date,
                 a.permno,
                 a.exchcd,
                 a.marketEquity,
                 b.bookEquity,
                 (1000 * b.bookEquity/a.decemberMarketEquity) AS bookToMarket,
                 b.compustatYears
        FROM     annualMarketEquityData     AS a,
                 linkedAnnualBookEquityData AS b
        WHERE    (a.permno = b.permno) AND
                 (INTNX('month', a.date, 0, 'E') = INTNX('month', INTNX('year', b.datadate, 0, 'E'), 6, 'E'));
QUIT;

PROC SORT
    DATA = annualRankingData;
    BY permno date;
RUN;

PROC PRINT
    DATA = annualRankingData(obs = 15);
    TITLE 'First 15 observations of annualRankingData.'; 
RUN;














;/*************************************************************************************
    @section: CREATE JUL(t) TO JUN(t+1) SIZE AND BOOK TO MARKET PORTFOLIOS
    -----------------------------------------------------------------------------------    
    @desc:    This section assigns each firm with a positive market equity and boook-to
              -market ratio over the last 5 years to 6 size and book-to-market buckets.
    -----------------------------------------------------------------------------------    
    @data:    marketEquityBreaksData
                                   market       market
              Obs         DATE    Equity33     Equity66

                1     19700630    58747.50    222810.25
                2     19710630    75945.38    280853.13
                3     19720630    76541.32    301259.49
                4     19730629    52453.70    212053.75
                5     19740628    42486.25    173360.25
    -----------------------------------------------------------------------------------    
    @data:    bookToMarketBreaksData
                                   bookTo      bookTo
              Obs         DATE    Market33    Market66

                1     19700630     0.47983     0.77275
                2     19710630     0.59345     0.99002
                3     19720630     0.57173     0.97487
                4     19730629     0.51625     0.89536
                5     19740628     0.83461     1.44527
    -----------------------------------------------------------------------------------    
    @data:    annualAssignmentData
                                                       valid
                                              valid     Book                   bookTo
                                             Market      To        size        Market
              Obs        DATE      PERMNO    Equity    Market    Portfolio    Portfolio

                1    19700630       10006       1         1         S2           V3    
                2    19710630       10006       1         1         S3           V2    
                3    19720630       10006       1         1         S2           V2    
                4    19730629       10006       1         1         S3           V3    
                5    19740628       10006       1         1         S3           V2    
                6    19700630       10014       0         0                            
                7    19710630       10014       1         1         S1           V3    
                8    19720630       10014       1         1         S1           V3    
                9    19730629       10014       1         1         S1           V3    
               10    19740628       10014       1         1         S1           V3    
               11    19700630       10057       1         1         S1           V3    
               12    19710630       10057       1         1         S1           V3    
               13    19720630       10057       1         1         S1           V3    
               14    19730629       10057       1         1         S1           V3    
               15    19740628       10057       1         1         S1           V2    
    -----------------------------------------------------------------------------------    
    @data:    portfolioData
                                                                                  valid
                                                                  valid  bookTo    Book
                                             portfolio   size    Market  Market     To
              Obs     DATE   PERMNO  retAdj    Weight  Portfolio Equity Portfolio Market

                1 19700731    10006 -0.01299 217178.50    S2        1      V3        1  
                2 19700831    10006  0.05526 214358.00    S2        1      V3        1  
                3 19700930    10006  0.09494 222819.50    S2        1      V3        1  
                4 19701030    10006 -0.04046 243973.25    S2        1      V3        1  
                5 19701130    10006  0.09277 234101.50    S2        1      V3        1  
                6 19701231    10006  0.01955 252434.75    S2        1      V3        1  
                7 19710129    10006  0.04384 257370.62    S2        1      V3        1  
                8 19710226    10006 -0.00577 268652.62    S2        1      V3        1  
                9 19710331    10006  0.09091 263716.75    S2        1      V3        1  
               10 19710430    10006  0.16176 287691.00    S2        1      V3        1  
               11 19710528    10006 -0.05105 334229.25    S2        1      V3        1  
               12 19710630    10006 -0.00674 313780.63    S2        1      V3        1  
               13 19710730    10006 -0.09276 310173.50    S3        1      V2        1  
               14 19710831    10006  0.16409 281401.75    S3        1      V2        1  
               15 19710930    10006 -0.00649 324208.50    S3        1      V2        1  
**************************************************************************************/

PROC SORT
    DATA = annualRankingData;
    BY date;
RUN;

PROC UNIVARIATE
    DATA = annualRankingData
    NOPRINT;
    WHERE (exchcd = 1)       AND
          (bookToMarket > 0) AND
          (marketEquity > 0) AND
          (compustatYears >= 5);
    VAR marketEquity;
    BY  date;
    OUTPUT OUT     = marketEquityBreaksData
           PCTLPTS = 50
           PCTLPRE = marketEquity;
RUN;

PROC SORT
    DATA = marketEquityBreaksData;
    BY date;
RUN;

PROC PRINT
    DATA = marketEquityBreaksData(obs = 15);
    TITLE 'First 15 observations of marketEquityBreaksData.'; 
RUN;

PROC SORT
    DATA = annualRankingData;
    BY date;
RUN;

PROC UNIVARIATE
    DATA = annualRankingData
    NOPRINT;
    WHERE (exchcd = 1)       AND
          (bookToMarket > 0) AND
          (marketEquity > 0) AND
          (compustatYears >= 5);
    VAR bookToMarket;
    BY  date;
    OUTPUT OUT     = bookToMarketBreaksData
           PCTLPTS = 30 70
           PCTLPRE = bookToMarket;
RUN;

PROC SORT
    DATA = bookToMarketBreaksData;
    BY date;
RUN;

PROC PRINT
    DATA = bookToMarketBreaksData(obs = 15);
    TITLE 'First 15 observations of bookToMarketBreaksData.'; 
RUN;

PROC SQL;
    CREATE TABLE annualAssignmentData AS
        SELECT a.*,
               b.marketEquity50,
               c.bookToMarket30,
               c.bookToMarket70
        FROM   annualRankingData      AS a,
               marketEquityBreaksData AS b,
               bookToMarketBreaksData AS c
        WHERE  (a.date = b.date = c.date);
QUIT;
        
DATA annualAssignmentData; 
    SET annualAssignmentData;
    If ((bookToMarket > 0) AND (marketEquity > 0) AND (compustatYears >= 5)) THEN
        DO;
        validMarketEquity = 1;        
        validBookToMarket = 1;        
        IF (marketEquity <= marketEquity50) THEN
            DO;
            sizePortfolio = 'S1';
            END;
        ELSE
            DO;
            sizePortfolio = 'S2';
            END;
        IF (bookToMarket <= bookToMarket30) THEN
            DO;
            bookToMarketPortfolio = 'V1';
            END;
        ELSE IF ((bookToMarket > bookToMarket30) AND (bookToMarket <= bookToMarket70)) THEN
            DO;
            bookToMarketPortfolio = 'V2';
            END;
        ELSE
            DO;
            bookToMarketPortfolio = 'V3';
            END;
        END;
    ELSE
        DO;
        validMarketEquity = 0;
        validBookToMarket = 0;
        END;
    KEEP permno
         date
         sizePortfolio
         validMarketEquity
         bookToMarketPortfolio
         validBookToMarket;
RUN;

PROC SORT
    DATA = annualAssignmentData;
    BY permno date;
RUN;

PROC PRINT
    DATA = annualAssignmentData(obs = 15);
    TITLE 'First 15 observations of annualAssignmentData.'; 
RUN;
















;/*************************************************************************************
    @section: COMPUTE MEAN PREFORMATION PERIOD RETURNS
    -----------------------------------------------------------------------------------    
    @desc:    This section computes the mean returns during each month prior to the
              formation period of the stocks in the HML portfolio.
    -----------------------------------------------------------------------------------    
    @data:    marketEquityBreaksData
**************************************************************************************/

%MACRO COMPUTE_PREFORMATION_HML_RETURNS(inputData1 = ,
                                        inputData2 = ,
                                        outputData = ,
                                        startYear  = ,
                                        endYear    = 
                                        );

    %LET numberOfYears = &endYear - &startYear;

    PROC SQL
        NOPRINT;
        CREATE TABLE &outputData(
            eventTime NUM,
            hml       NUM,
            year      NUM
            );
    QUIT;
        
    %DO i=0 %TO &numberOfYears;

        %LET currentYear = &startYear + &i;        

        PROC SQL;
            CREATE TABLE tempData AS
                SELECT   a.date,
                         a.permno,
                         a.sizePortfolio,
                         a.bookToMarketPortfolio
                FROM     &inputData1 AS a
                WHERE    (YEAR(a.date) = &currentYear) AND
                         (a.validMarketEquity = 1)     AND
                         (a.validBookToMarket = 1);
        QUIT; 

        PROC SORT
        DATA = tempData;
            BY permno date;
        RUN;
                
        PROC SQL;
            CREATE TABLE eventData AS
                SELECT   a.date,
                         a.permno,
                         a.retAdj,
                         a.portfolioWeight,
                         b.sizePortfolio,
                         b.bookToMarketPortfolio,
                         ((-1) * INTCK('month', a.date, b.date) - 1) AS eventTime
                FROM     &inputData2 AS a,
                         tempData   AS b
                WHERE    (a.permno = b.permno) AND
                         (INTCK('month', a.date, b.date) BETWEEN 0 AND 41);
        QUIT; 

        PROC SORT
        DATA = eventData;
            BY eventTime sizePortfolio bookToMarketPortfolio;
        RUN;

        PROC UNIVARIATE
        DATA = eventData
               NOPRINT;
            VAR    retAdj;
            WEIGHT portfolioWeight;
            BY     eventTime sizePortfolio bookToMarketPortfolio;
            OUTPUT OUT  = meanRetData
                   MEAN = meanRet;
        RUN;
        
        PROC SORT
        DATA = meanRetData;
            BY eventTime sizePortfolio bookToMarketPortfolio;
        RUN;
        
        PROC TRANSPOSE
        DATA    = meanRetData
        OUT     = meanRetData;
            BY eventTime;
            ID sizePortfolio bookToMarketPortfolio;
            VAR meanRet;
        RUN;
        
        DATA meanRetData;
            SET meanRetData;
            hml  = ((s2v3 + s1v3) - (s2v1 + s1v1))/2;
            year = &currentYear;
            KEEP eventTime hml year;
        RUN;

        PROC DATASETS
            NOLIST;
            APPEND BASE = &outputData
                   DATA = meanRetData
                   FORCE;
        RUN;
        
        %END;
    
    %MEND;

%COMPUTE_PREFORMATION_HML_RETURNS(inputData1 = annualAssignmentData,
                                  inputData2 = stockReturnData,
                                  outputData = dt97Fig1Data,
                                  startYear  = 1963,
                                  endYear    = 1993
                                  );


PROC SORT
    DATA = dt97Fig1Data;
    BY year eventTime;
RUN;

PROC PRINT
    DATA = dt97Fig1Data(obs = 15);
    TITLE 'First 15 observations of dt97Fig1Data.'; 
RUN;

PROC EXPORT
    DATA    = dt97Fig1Data
    OUTFILE = "dt97-figure1-data.csv"
    DBMS    = CSV
    REPLACE;    
RUN;



