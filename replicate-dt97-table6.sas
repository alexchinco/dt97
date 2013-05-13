;/*************************************************************************************
    @title:  REPLICATE DANIEL AND TITMAN (1997)
    -----------------------------------------------------------------------------------    
    @author: Alex Chinco
    @date:   09/05/2013
    -----------------------------------------------------------------------------------    
    @desc:   This program replicates Tables 3 and 6 in Daniel and Titman (1997) by
             computing the variation in excess and abnormal returns within 9 portfolios
             sorted on size and book to market ratio according to the pre-sample book
             to market ratio (e.g., the characteristic level).

             Note: All sample data created using &startDate = '01JUL1968'd and &endData =
             '31DEC1974'd.
**************************************************************************************/

LIBNAME comp  '/wrds/comp/sasdata/naa';
LIBNAME crsp  '/wrds/crsp/sasdata/a_stock';
LIBNAME cc    '/wrds/crsp/sasdata/a_ccm';
LIBNAME ff    '/wrds/ff/sasdata';

%LET startDate = '01JUN1961'd;
%LET endDate   = '31DEC1993'd;

%LET startYear  = 1973;
%LET endYear    = 1993;
%LET minHistory = 0;










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
                 (1000 * b.bookEquity/a.decemberMarketEquity) AS bookToMarket
        FROM     annualMarketEquityData     AS a,
                 linkedAnnualBookEquityData AS b
        WHERE    (a.permno = b.permno) AND
                 (INTNX('month', a.date, 0, 'E') = INTNX('month', INTNX('year', b.datadate, 0, 'E'), 6, 'E'));
QUIT;

DATA annualRankingData;
    SET annualRankingData;
    BY  permno date;
    WHERE (marketEquity > 0) AND
          (bookEquity > 0);
    RETAIN compustatYears;
    IF first.permno THEN
        DO;
        compustatYears = 1;
        END;
    ELSE
        DO;
        compustatYears = compustatYears + 1;
        END;
RUN;

PROC SORT
    DATA = annualRankingData;
    BY permno date;
RUN;

PROC PRINT
    DATA = annualRankingData(obs = 15);
    TITLE 'First 15 observations of annualRankingData.'; 
RUN;












;/*************************************************************************************
    @section: CREATE SIZE AND BOOK TO MARKET PORTFOLIOS
    -----------------------------------------------------------------------------------    
    @desc:    This section computes the returns to 9 portfolios sorted by size and book
              to market ratio as of each June t using NYSE breakpoints at 33% and 66%
              using stocks with at least 2 years of prior data in COMPUSTAT.
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
          (compustatYears >= &minHistory);
    VAR marketEquity;
    BY  date;
    OUTPUT OUT     = marketEquityBreaksData
           PCTLPTS = 33 66
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
          (compustatYears >= &minHistory);
    VAR bookToMarket;
    BY  date;
    OUTPUT OUT     = bookToMarketBreaksData
           PCTLPTS = 33 66
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
               b.marketEquity33,
               b.marketEquity66,
               c.bookToMarket33,
               c.bookToMarket66
        FROM   annualRankingData      AS a,
               marketEquityBreaksData AS b,
               bookToMarketBreaksData AS c
        WHERE  (a.date = b.date = c.date);
QUIT;
        
DATA annualAssignmentData; 
    SET annualAssignmentData;
    If ((bookToMarket > 0) AND (marketEquity > 0) AND (compustatYears >= &minHistory)) THEN
        DO;
        validMarketEquity = 1;        
        validBookToMarket = 1;        
        IF ((marketEquity <= marketEquity33) AND (marketEquity > 0)) THEN
            DO;
            sizePortfolio = 'S1';
            END;
        ELSE IF ((marketEquity > marketEquity33) AND (marketEquity <= marketEquity66)) THEN
            DO;
            sizePortfolio = 'S2';
            END;
        ELSE IF (marketEquity > marketEquity66) THEN
            DO;
            sizePortfolio = 'S3';
            END;
        ELSE
            DO;
            sizePortfolio = '';
            END;
        IF ((bookToMarket <= bookToMarket33) AND (bookToMarket >  0)) THEN
            DO;
            bookToMarketPortfolio = 'V1';
            END;
        ELSE IF ((bookToMarket > bookToMarket33) AND (bookToMarket <= bookToMarket66)) THEN
            DO;
            bookToMarketPortfolio = 'V2';
            END;
        ELSE IF (bookToMarket > bookToMarket66) THEN
            DO;
            bookToMarketPortfolio = 'V3';
            END;
        ELSE
            DO;
            bookToMarketPortfolio = '';
            END;
        END;
    ELSE
        DO;
        validMarketEquity = 0;
        validBookToMarket = 0;
        END;
    KEEP permno
         date
         compustatYears
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
    @section: LOAD FAMA AND FRENCH (1993) HML AND SMB FACTORS AND MKT RETURNS
    -----------------------------------------------------------------------------------    
    @desc:    This section loads on the Fama and French (1993) factors as well as the
              excess return on the market from the WRDS database.
    -----------------------------------------------------------------------------------    
    @data:    portfolioData
                                                                        valid   bookTo
                                                 portfolio    size     Market   Market
              Obs      DATE    PERMNO   retAdj     Weight   Portfolio  Equity  Portfolio

                1  19700731     10006  -0.01299  217178.50     S2         1       V3    
                2  19700831     10006   0.05526  214358.00     S2         1       V3    
                3  19700930     10006   0.09494  222819.50     S2         1       V3    
                4  19701030     10006  -0.04046  243973.25     S2         1       V3    
                5  19701130     10006   0.09277  234101.50     S2         1       V3    
                6  19701231     10006   0.01955  252434.75     S2         1       V3    
                7  19710129     10006   0.04384  257370.62     S2         1       V3    
                8  19710226     10006  -0.00577  268652.62     S2         1       V3    
                9  19710331     10006   0.09091  263716.75     S2         1       V3    
               10  19710430     10006   0.16176  287691.00     S2         1       V3    
               11  19710528     10006  -0.05105  334229.25     S2         1       V3    
               12  19710630     10006  -0.00674  313780.63     S2         1       V3    
               13  19710730     10006  -0.09276  310173.50     S3         1       V2    
               14  19710831     10006   0.16409  281401.75     S3         1       V2    
               15  19710930     10006  -0.00649  324208.50     S3         1       V2    

                   valid
                    Book
                     To
              Obs  Market          mkt          rf          hml          smb

                1     1       0.069000     0.00520     0.010500    -0.005600
                2     1       0.044700     0.00530     0.010800     0.015200
                3     1       0.042100     0.00540    -0.055000     0.086200
                4     1      -0.022800     0.00460     0.002100    -0.042200
                5     1       0.045800     0.00460     0.016900    -0.040700
                6     1       0.056500     0.00420     0.009800     0.029300
                7     1       0.048200     0.00380     0.013500     0.074300
                8     1       0.013600     0.00330    -0.013400     0.018900
                9     1       0.041800     0.00300    -0.039900     0.025800
               10     1       0.030500     0.00280     0.007400    -0.004900
               11     1      -0.039300     0.00290    -0.013700    -0.011100
               12     1      -0.000600     0.00370    -0.020000    -0.014300
               13     1      -0.044300     0.00400     0.001600    -0.015000
               14     1       0.037800     0.00470     0.027000    -0.002100
               15     1      -0.008700     0.00370    -0.029400     0.004200
**************************************************************************************/

PROC SQL;
    CREATE TABLE ff93Data AS
        SELECT a.date,
               a.mktrf AS mkt,
               a.rf,
               a.hml,
               a.smb
        FROM   ff.factors_monthly AS a
        WHERE (&startDate <= a.date <= &endDate);
QUIT;

PROC SORT
    DATA = ff93Data;
    BY date;
RUN;

PROC PRINT
    DATA = ff93Data(obs = 15);
    TITLE 'First 15 observations of ff93Data.'; 
RUN;
















;/*************************************************************************************
    @section: COMPUTE PER-FORMATION HML LOADINGS
    -----------------------------------------------------------------------------------    
    @desc:    This section computes the HML factor loading for each stock in month t
              over the time period from (t-42) to (t-7), creates 5 HML loading buckets
              using the 20%, 40%, 60%, and 80% break points, and then merges this data
              onto the existing (permno,month) stock returns data.
    -----------------------------------------------------------------------------------    
    @data:    hmlLoadingRankingData
                                                               valid
                                           valid                Book     bookTo
                                          Market     size        To      Market        hml
              Obs       DATE     PERMNO   Equity   Portfolio   Market   Portfolio    Loading

                1   19730731      10006      1        S3          1        V3       -0.14558
                2   19730731      10014      1        S1          1        V3        0.82946
                3   19730731      10057      1        S1          1        V3        1.22678
                4   19730731      10102      1        S2          1        V3        0.61032
                5   19730731      10137      1        S3          1        V2       -0.13941
                6   19730731      10145      1        S3          1        V3        1.94637
                7   19730731      10153      1        S2          1        V3        1.24644
                8   19730731      10161      1        S3          1        V3       -0.16681
                9   19730731      10188      1        S1          1        V3        1.05227
               10   19730731      10189      1        S1          1        V1         .     
               11   19730731      10225      1        S3          1        V2        0.12074
               12   19730731      10233      1        S3          1        V1       -2.02411
               13   19730731      10241      1        S3          1        V3        1.07523
               14   19730731      10268      0                    0                   .     
               15   19730731      10277      0                    0                   .     
    -----------------------------------------------------------------------------------    
    @data:    hmlLoadingBreaksData
                                         bookTo
                               size      Market       hml        hml        hml        hml
              Obs      DATE  Portfolio  Portfolio  Loading20  Loading40  Loading60  Loading80

                1  19730731     S1         V1       -1.17182   -0.42784    0.33142   1.10641 
                2  19730731     S1         V2       -0.58861    0.18994    0.66367   1.38098 
                3  19730731     S1         V3       -0.27168    0.35957    0.92291   1.52606 
                4  19730731     S2         V1       -1.02507   -0.40552    0.01049   0.74616 
                5  19730731     S2         V2       -0.45436    0.14038    0.45551   0.83197 
                6  19730731     S2         V3        0.04999    0.42675    0.88238   1.26742 
                7  19730731     S3         V1       -0.82228   -0.41142   -0.01444   0.33209 
                8  19730731     S3         V2       -0.13926    0.14913    0.50116   0.78299 
                9  19730731     S3         V3       -0.07445    0.30748    0.69924   1.09207 
               10  19730831     S1         V1       -1.22408   -0.42696    0.18974   1.05324 
               11  19730831     S1         V2       -0.53039    0.15328    0.67275   1.26613 
               12  19730831     S1         V3       -0.25353    0.40399    0.94960   1.53129 
               13  19730831     S2         V1       -0.95407   -0.43078   -0.03692   0.70924 
               14  19730831     S2         V2       -0.46258    0.12114    0.42756   0.81204 
               15  19730831     S2         V3       -0.00208    0.44992    0.89345   1.28957 
    -----------------------------------------------------------------------------------    
    @data:    hmlLoadingAssignmentData
                                              valid        hml
                                               Hml       Loading
              Obs        DATE      PERMNO    Loading    Portfolio

                1    19730731       10006       1         hml3   
                2    19730731       10006       1         hml2   
                3    19730731       10006       1         hml2   
                4    19730731       10006       1         hml3   
                5    19730731       10006       1         hml2   
                6    19730731       10006       1         hml1   
                7    19730731       10006       1         hml3   
                8    19730731       10006       1         hml1   
                9    19730731       10006       1         hml1   
               10    19730831       10006       1         hml3   
               11    19730831       10006       1         hml2   
               12    19730831       10006       1         hml2   
               13    19730831       10006       1         hml3   
               14    19730831       10006       1         hml2   
               15    19730831       10006       1         hml1   
    -----------------------------------------------------------------------------------    
    @data:    portfolioData
                                                                  b
                                                                  o
                                                                  o          h
                                                                  k          m
                                                               v  T   v      l
                                                               a  o   a      L
                                                    p          l  M   l  v   o
                                                    o          i  a   i  a   a
                                                    r      s   d  r   d  l   d
                                                    t      i   M  k   B  i   i
                                                    f      z   a  e   o  d   n
                                                    o      e   r  t   o  H   g
                                                    l      P   k  P   k  m   P
                                                    i      o   e  o   T  l   o
                                                    o      r   t  r   o  L   r
                                  P      r          W      t   E  t   M  o   t
                                  E      e          e      f   q  f   a  a   f
                        D         R      t          i      o   u  o   r  d   o
              O         A         M      A          g      l   i  l   k  i   l
              b         T         N      d          h      i   t  i   e  n   i
              s         E         O      j          t      o   y  o   t  g   o

              1  19730731     10006   0.057692  255073.00  S3  1  V3  1  1  hml3
              2  19730731     10006   0.057692  255073.00  S3  1  V3  1  1  hml2
              3  19730731     10006   0.057692  255073.00  S3  1  V3  1  1  hml2
              4  19730731     10006   0.057692  255073.00  S3  1  V3  1  1  hml3
              5  19730731     10006   0.057692  255073.00  S3  1  V3  1  1  hml2
              6  19730731     10006   0.057692  255073.00  S3  1  V3  1  1  hml1
              7  19730731     10006   0.057692  255073.00  S3  1  V3  1  1  hml3
              8  19730731     10006   0.057692  255073.00  S3  1  V3  1  1  hml1
              9  19730731     10006   0.057692  255073.00  S3  1  V3  1  1  hml1
             10  19730831     10006  -0.094026  269788.75  S3  1  V3  1  1  hml3
             11  19730831     10006  -0.094026  269788.75  S3  1  V3  1  1  hml2
             12  19730831     10006  -0.094026  269788.75  S3  1  V3  1  1  hml2
             13  19730831     10006  -0.094026  269788.75  S3  1  V3  1  1  hml3
             14  19730831     10006  -0.094026  269788.75  S3  1  V3  1  1  hml2
             15  19730831     10006  -0.094026  269788.75  S3  1  V3  1  1  hml1
**************************************************************************************/    
    
%MACRO ROLLING_REGRESSION(inputData1 = ,
                          inputData2 = ,
                          inputData3 = ,
                          outputData = ,
                          startYear  = ,
                          endYear    = 
                          );

    %LET numberOfYears = &endYear - &startYear;

    PROC SQL
        NOPRINT;
        CREATE TABLE &outputData(
            permno     NUM,
            date       NUM FORMAT = date9.,
            hmlLoading NUM
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

        PROC SQL;
            CREATE TABLE regressionData AS
                SELECT   a.date,
                         a.permno,
                         a.retAdj
                FROM     &inputData2 AS a,
                         tempData    AS b
                WHERE    (a.permno = b.permno) AND
                         (INTCK('month', a.date, b.date) BETWEEN 6 AND 41);
        QUIT; 
        
        PROC SQL;
            CREATE TABLE regressionData AS
                SELECT   a.date,
                         a.permno,
                         (a.retAdj - b.rf) AS retx,
                         b.mkt,
                         b.hml,
                         b.smb
                FROM     regressionData AS a,
                         &inputData3    AS b
                WHERE    (YEAR(a.date) = YEAR(b.date)) AND
                         (MONTH(a.date) = MONTH(b.date));
        QUIT; 

        PROC SORT
        DATA = regressionData;
            BY permno;
        RUN;

        PROC REG
            NOPRINT
            DATA   = regressionData
            OUTEST = hmlLoadingData;
            MODEL retx = hml smb mkt;
            BY permno;
        RUN;
        
        DATA hmlLoadingData;
            SET hmlLoadingData;
            date       = MDY(6,30,&currentYear);
            hmlLoading = hml;
            KEEP permno
                 date
                 hmlLoading;
        RUN;

        PROC DATASETS
            NOLIST;
            APPEND BASE = &outputData
                   DATA = hmlLoadingData
                   FORCE;
        RUN;

        %END;

    %MEND;

%ROLLING_REGRESSION(inputData1 = annualAssignmentData,
                    inputData2 = stockReturnData,
                    inputData3 = ff93Data,
                    outputData = hmlLoadingRankingData,
                    startYear  = &startYear,
                    endYear    = &endYear
                    );

PROC SORT
    DATA = hmlLoadingRankingData;
    BY date permno;
RUN;

PROC PRINT
    DATA = hmlLoadingRankingData(obs = 15);
    TITLE 'First 15 observations of hmlLoadingRankingData.'; 
RUN;

PROC SQL;
    CREATE TABLE hmlLoadingRankingData AS
        SELECT a.date,
               a.permno,
               a.compustatYears,
               a.validMarketEquity,
               a.sizePortfolio,
               a.validBookToMarket,
               a.bookToMarketPortfolio,
               b.hmlLoading
        FROM   annualAssignmentData  AS a LEFT JOIN
               hmlLoadingRankingData AS b
        ON     (a.permno = b.permno) AND
               (YEAR(a.date) = YEAR(b.date));
QUIT;

PROC SORT
    DATA = hmlLoadingRankingData;
    BY date permno;
RUN;

PROC PRINT
    DATA = hmlLoadingRankingData(obs = 15);
    TITLE 'First 15 observations of hmlLoadingRankingData.'; 
RUN;

PROC SORT
    DATA = hmlLoadingRankingData;
    BY date sizePortfolio bookToMarketPortfolio;
RUN;

PROC UNIVARIATE
    DATA = hmlLoadingRankingData
    NOPRINT;
    WHERE (NOT MISSING(hmlLoading)) AND
          (validBookToMarket = 1)   AND
          (validMarketEquity = 1)   AND
          (compustatYears >= &minHistory);
    VAR hmlLoading;
    BY  date sizePortfolio bookToMarketPortfolio;
    OUTPUT OUT     = hmlLoadingBreaksData
           PCTLPTS = 20 40 60 80
           PCTLPRE = hmlLoading;
RUN;

PROC SORT
    DATA = hmlLoadingBreaksData;
    BY date sizePortfolio bookToMarketPortfolio;
RUN;

PROC PRINT
    DATA = hmlLoadingBreaksData(obs = 15);
    TITLE 'First 15 observations of the hmlLoadingBreaksData.'; 
RUN;

PROC SQL;
    CREATE TABLE hmlLoadingAssignmentData AS
        SELECT a.date,
               a.permno,
               a.validBookToMarket,
               a.validMarketEquity,
               a.hmlLoading,
               b.hmlLoading20,
               b.hmlLoading40,
               b.hmlLoading60,
               b.hmlLoading80
        FROM   hmlLoadingRankingData AS a,
               hmlLoadingBreaksData  AS b
        WHERE  (a.date = b.date);
QUIT;

DATA hmlLoadingAssignmentData; 
    SET hmlLoadingAssignmentData;
    IF (validMarketEquity = 1) AND (validBookToMarket = 1) AND (NOT MISSING(hmlLoading)) THEN
        DO;
        validHmlLoading = 1;        
        IF (hmlLoading <= hmlLoading20) THEN
            DO;
            hmlLoadingPortfolio = 'hml1';
            END;
        ELSE IF ((hmlLoading > hmlLoading20) AND (hmlLoading <= hmlLoading40)) THEN
            DO;
            hmlLoadingPortfolio = 'hml2';
            END;
        ELSE IF ((hmlLoading > hmlLoading40) AND (hmlLoading <= hmlLoading60)) THEN
            DO;
            hmlLoadingPortfolio = 'hml3';
            END;
        ELSE IF ((hmlLoading > hmlLoading60) AND (hmlLoading <= hmlLoading80)) THEN
            DO;
            hmlLoadingPortfolio = 'hml4';
            END;
        ELSE IF (hmlLoading > hmlLoading80) THEN
            DO;
            hmlLoadingPortfolio = 'hml5';
            END;
        ELSE
            DO;
            hmlLoadingPortfolio = '';
            END;
        END;
    ELSE
        DO;
        validHmlLoading = 0;
        END;
    KEEP permno
         date
         validHmlLoading
         hmlLoadingPortfolio;
RUN;

PROC SORT
    DATA = hmlLoadingAssignmentData;
    BY permno date;
RUN;

PROC PRINT
    DATA = hmlLoadingAssignmentData(obs = 15);
    TITLE 'First 15 observations of hmlLoadingAssignmentData.'; 
RUN;

PROC SQL;
    CREATE TABLE annualAssignmentData AS
        SELECT   a.date,
                 a.permno,
                 a.compustatYears,
                 a.sizePortfolio,
                 a.validMarketEquity,
                 a.bookToMarketPortfolio,
                 a.validBookToMarket,
                 b.hmlLoadingPortfolio,
                 b.validHmlLoading
        FROM     annualAssignmentData     AS a,
                 hmlLoadingAssignmentData AS b
        WHERE    (a.permno = b.permno) AND
                 (YEAR(a.date)  = YEAR(b.date));
QUIT; 

PROC SORT
    DATA = annualAssignmentData;
    BY permno date;
RUN;

PROC PRINT
    DATA = annualAssignmentData(obs = 15);
    TITLE 'First 15 observations of annualAssignmentData.'; 
RUN;




















;/*************************************************************************************
    @section: COMPUTE DANIEL AND TITMAN (1997) CHARACTERISTIC RETURNS
    -----------------------------------------------------------------------------------    
    @desc:    This section collapses the (permo,month) data by size, book to market,
              and HML loading buckets to create 45 observations per month. I then merge
              on the Fama and French (1993) factor data and the excess return on the
              value weighted market.
    -----------------------------------------------------------------------------------    
    @data:    danielTitman97Data
                            b
                            o
                            o   h
                            k   m
                            T   l
                            o   L
                            M   o
                            a   a
                         s  r   d            n
                         i  k   i            u
                         z  e   n            m
                         e  t   g            b
                         P  P   P            e
                         o  o   o            r
                         r  r   r            O
                         t  t   t            f
                         f  f   f            F
                       D o  o   o            i
              O        A l  l   l      r     r          m                  h         s
              b        T i  i   i      e     m          k        r         m         m
              s        E o  o   o      t     s          t        f         l         b

              1 19730731 S1 V1 hml1 0.21856 803  0.050600  0.00640 -0.051800  0.078600
              2 19730731 S3 V3 hml5 0.04351 199  0.050600  0.00640 -0.051800  0.078600
              3 19730731 S3 V3 hml4 0.01857 199  0.050600  0.00640 -0.051800  0.078600
              4 19730731 S3 V3 hml3 0.02479 199  0.050600  0.00640 -0.051800  0.078600
              5 19730731 S3 V3 hml2 0.06986 140  0.050600  0.00640 -0.051800  0.078600
              6 19730731 S3 V3 hml1 0.05899  82  0.050600  0.00640 -0.051800  0.078600
              7 19730731 S3 V2 hml5 0.05524 203  0.050600  0.00640 -0.051800  0.078600
              8 19730731 S3 V2 hml4 0.02113 330  0.050600  0.00640 -0.051800  0.078600
              9 19730731 S3 V2 hml3 0.00613 361  0.050600  0.00640 -0.051800  0.078600
             10 19730731 S3 V2 hml2 0.00683 282  0.050600  0.00640 -0.051800  0.078600
             11 19730731 S3 V2 hml1 0.03068 165  0.050600  0.00640 -0.051800  0.078600
             12 19730731 S3 V1 hml5 0.07999 104  0.050600  0.00640 -0.051800  0.078600
             13 19730731 S3 V1 hml4 0.05014 243  0.050600  0.00640 -0.051800  0.078600
             14 19730731 S3 V1 hml3 0.05815 392  0.050600  0.00640 -0.051800  0.078600
             15 19730731 S3 V1 hml2 0.05256 591  0.050600  0.00640 -0.051800  0.078600
**************************************************************************************/    

PROC SQL;
    CREATE TABLE portfolioData AS
        SELECT a.*,
               b.retAdj,
               b.portfolioWeight
        FROM   annualAssignmentData AS a,
               stockReturnData      AS b
        WHERE (a.permno = b.permno) AND
              (INTCK('month', a.date, b.date) BETWEEN 1 AND 12);
QUIT;
    
PROC SORT
    DATA = portfolioData;
    BY date
       sizePortfolio
       bookToMarketPortfolio
       hmlLoadingPortfolio;
RUN;

PROC PRINT
    DATA = portfolioData(obs = 15);
    TITLE 'First 15 observations of portfolioData.'; 
RUN;

PROC MEANS
    DATA = portfolioData
    NOPRINT;
    WHERE (validMarketEquity = 1) AND
          (validBookToMarket = 1) AND
          (validHmlLoading = 1)   AND
          (compustatYears >= &minHistory);
    BY date
       sizePortfolio
       bookToMarketPortfolio
       hmlLoadingPortfolio;
    VAR retAdj;
    WEIGHT portfolioWeight;
    OUTPUT OUT  = danielTitman97Data(DROP = _type_ _freq_)
           MEAN = ret
           N    = numberOfFirms;
RUN;

PROC SQL;
    CREATE TABLE danielTitman97Data AS
        SELECT a.*,
               b.mktrf AS mkt,
               b.rf,
               b.hml,
               b.smb
        FROM   danielTitman97Data AS a,
               ff.factors_monthly AS b
        WHERE (MONTH(a.date) = MONTH(b.date)) AND
              (YEAR(a.date) = YEAR(b.date));
QUIT;

PROC SORT
    DATA = danielTitman97Data;
    BY date;
RUN;

PROC PRINT
    DATA = danielTitman97Data(obs = 15);
    TITLE 'First 15 observations of danielTitman97Data.'; 
RUN;

PROC EXPORT
    DATA    = danielTitman97Data
    OUTFILE = "dt97-table6-data.csv"
    DBMS    = CSV
    REPLACE;    
RUN;



