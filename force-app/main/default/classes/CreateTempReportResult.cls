public class CreateTempReportResult{    

    public static void CreateTicketSearchFromReport(){
        //This will be the initial filter for the report until it runs a second time.
        //the second time and on, the filter gets dynamically assigned the autonumuber related to the bottommost id on the report.
        String filterNumber = '0';

        //initialize numOfRow at 1. When it gets reassigned to 0, stop the while loop
        string firstid;
        Integer numOfRows = 1;
        Integer loopCount = 0;
        Boolean Filterval = False;
        

        //create a set of report results To be populated in the for loop. Sets removes possibility of dupes.
         List<Search_Result_Ticket__c> tempSearchResults = new  List<Search_Result_Ticket__c>();
        //create list for insert at the end
        List<Search_Result_Ticket__c> tempSearchResultsList = new List<Search_Result_Ticket__c>();
        Boolean manualBreak = false;

        //break loop when report stops returning results, or when told to break.
        while(numOfRows>0 && !manualBreak){
            loopCount++;
            
            Report repRec=[SELECT Id,Name,DeveloperName from Report where DeveloperName=:'Ticket_Search_Result_Report' limit 1];
            Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(repRec.Id);


            // Get the report metadata in order to create dynamic filter (since reports run with a maximum of 2,000 return results)
            //Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(repRec);
            //Reports.ReportMetadata reportMd = describe.getReportMetadata();           
           // Reports.ReportFilter filter = reportMd.getReportFilters()[0];
            //filter.setValue(string.valueOf(Filterval));                              

            // Run a report synchronously
            Reports.ReportResults searchReportResults = Reports.ReportManager.runReport(repRec.Id,true);
            searchReportResults.getAllData();
            system.debug('ReportResultsJSON'+JSON.serialize( searchReportResults));

            // Get the fact map from the report results
             Reports.ReportFactWithDetails factDetails =(Reports.ReportFactWithDetails)searchReportResults.getFactMap().get('T!T');

            //create a list of report rows and populate it with the result rows from fact map
            List<Reports.ReportDetailRow> reportRows = factDetails.getRows();

            numOfRows = reportRows.size();
            System.debug('Value of numOfRows: ' + numOfRows);
            //loop through each report detail row and create a record

            //loop throgh row by row the get the data
            for(integer count = 0; count<numOfRows;count++){                        

                List<Reports.ReportDataCell> datacells = reportRows[count].getDataCells();
                Reports.ReportDataCell datacell = datacells[0];
                String cmsnextId = (string)datacell.getValue();
                 

                //make sure loop doesn't enter infinite loop
                if(count==0 && loopCount>1 && firstid==cmsnextId){
                    manualBreak = true;
                    break;
                }

                //set conid to firstconid for reference in the next loop
                if(count==0){                       
                    firstid = cmsnextId;                     
                }

                Search_Result_Ticket__c sTicket = new Search_Result_Ticket__c(
                    Ticket_Registration_Number__c=String.ValueOf(datacells[0].getValue()),
                    Ticket_Record_Type__c=String.ValueOf(datacells[2].getValue()),
                    //Ticket_Receipt_Date__c= DateTime.ValueOf(date.format(datacells[3].getValue()),
                    FA_Quality_Assignee_Pending_MDCs__c=Boolean.ValueOf(datacells[4].getValue()),
                    Med_Evaluator_Pending_MDCs__c=Boolean.ValueOf(datacells[5].getValue()),
                    Product_List_Part_Number__c=String.ValueOf(datacells[6].getValue()),
                    Trending_Experience_Bucket__c=String.ValueOf(datacells[7].getValue()),
                        Experience_Code__c=String.ValueOf(datacells[8].getValue()),
                        ssue_Code__c=String.ValueOf(datacells[9].getValue()),
                     // Quality_Directive_Number_Modified_Date__c=DateTime.ValueOf(datacells[10].getValue()),
                        Quality_Directive_Number__c=String.ValueOf(datacells[11].getValue()),    
                   TSB_Number__c=String.ValueOf(datacells[12].getValue()),
                        //MDC_Last_Updated_Date__c=Date.ValueOf(datacells[13].getValue()),
                    Overall_Reportable_Status__c=String.ValueOf(datacells[14].getValue()));
               
                
                tempSearchResults.add(sTicket);

                //HERE's WHERE YOU SET THE FILTER TO DYNAMICALLY CHANGE (only get it when you're in the last row of the report results)**
                //if(count==numOfRows-1){
                   //filterNumber= [Select Record_Number__c FROM CMPL123CME__Complaint__c WHERE CMSNext_Ticket_ID__c= :cmsnextId].Record_Number__c;
               // }

            }
        }
        tempSearchResultsList.addall(tempSearchResults);
        Database.insert(tempSearchResultsList,false);
    }       
}