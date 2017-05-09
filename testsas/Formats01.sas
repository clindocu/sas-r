;/******************************************************************;
********** DEFINITION OF SAS FORMATS (work.formats);
********************************************************************/

********** Definition of SAS Formats;
********** NOTE: The 'notsorted' option preserves the rank order, here M, F (can be very useful);
********** NOTE: Only 'simple' formats can be used, eg. 'Data-value-1' = 'Label 1';
proc format;
    value $SEX (notsorted)
               "M"="Male"
               "F"="Female";

    value $ORIGIN "Asia"="ASIA"
                  "Europe"="EUROPE"
                  "USA"="USA";

    value CYL 3='3 cylinders'
              4='4 cylinders'
              5='5 cylinders'
              6='6 cylinders'
              8='8 cylinders'
             10='10 cylinders'
             12='12 cylinders';
run;
quit;
