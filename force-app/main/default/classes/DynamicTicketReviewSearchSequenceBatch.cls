/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : DynamicTicketReviewSearchSequenceBatch.
* @Why   : This batch class is used to create Ticket_Search_Result__c records.
* @When  : 05-MAR-2019.
* @Where : From DynamicTicketReviewSearchController class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                 Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin             05-MAR-2019      Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin             07-MAR-2019      Work ID / Case ID    Updated.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020          Code Audit           Removed Commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    13-JUL-2020          Code Audit           Removed Commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* Juneid                  22 June 2021         MIR Devlopment         Added a Logic for MIR in Ticket Review Search
* --------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar            20 JUL 2024          CHaRM-R5/IPDR 191      Added new method "getStartAndEndDate"
                                                                      Updated "notifyUserOnComplition","start", "Execute", "Finish"                                                                     
* --------------------------------------------------------------------------------------------------------------------------------------
*/
global class DynamicTicketReviewSearchSequenceBatch implements Database.Batchable<sObject> {

    Private String strQuery; // Query String
    Private Set<String> setChildQueryOnly; // Child Query Set
    Private String strTicketReviewId; // Related Ticket Review Id
    Private Boolean isParent = false; // To check the query is ( complaint and related child ) OR Child only

    Private Map<String,String> mapChildObjectAPIAndTicketField = New Map<String,String>();
    Private Map<String,String> mapChildObjectAPINameAndQuery = New Map<String,String>();
    Private Set<String> setobjectsIncludedInSearch = New Set<String>();
    Private Set<String> setSearchingChildObjects = New Set<String>();

    Private List<Map<String,String>> lstJSONDataToBatch = New List<Map<String,String>>();
    Private Integer intCounterIndex = 0;
    
    Private DateTime startDate;//CHaRM-R5
    Private DateTime endDate;//CHaRM-R5
    Private Integer  dateRange;//Charm-R5    
    /*
    * @Constructor  : DynamicTicketReviewSearchSequenceBatch.
    * @Description  : To execute logic upon class initialization.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : String strQuery, String strTicketReviewId, Boolean isParent,
                      Map<String,String> mapChildObjectAPIAndTicketField,
                      Map<String,String> mapChildObjectAPINameAndQuery, Set<String> setobjectsIncludedInSearch.
    */
    public DynamicTicketReviewSearchSequenceBatch(List<Map<String,String>> lstJSONDataToBatch, Integer intCounterIndex){
        this.intCounterIndex = intCounterIndex;
        this.lstJSONDataToBatch = lstJSONDataToBatch;
        Map<String,String> mapDataJSON = lstJSONDataToBatch[intCounterIndex];
        //CHaRM-R5: Added date range and to include in the batch query 
        dateRange = (Integer)CHaRM_Misc_Settings__c.getOrgDefaults().TicketReviewSearchRange__c;        
        for(String strKey : mapDataJSON.keySet()){
            this.isParent = mapDataJSON.get('isParent') == 'TRUE' ? true : false;
            this.strQuery = mapDataJSON.get('query');
            this.strTicketReviewId = mapDataJSON.get('ticketReviewId');
            if(!this.isParent){
                this.strQuery = 'SELECT Id FROM ACCOUNT'; // Dummy Query
                this.setChildQueryOnly = (Set<String>)System.JSON.deserialize(mapDataJSON.get('childObjQuery'), Set<String>.class);
            }
            this.setobjectsIncludedInSearch = (Set<String>)System.JSON.deserialize(mapDataJSON.get('objectsIncludedInSearchSet'), Set<String>.class);
            this.mapChildObjectAPIAndTicketField = (Map<String,String>)System.JSON.deserialize(mapDataJSON.get('childObjectAPIAndTicketFieldMap'), Map<String,String>.class);
            this.mapChildObjectAPINameAndQuery = (Map<String,String>)System.JSON.deserialize(mapDataJSON.get('childObjectAPINameAndQueryMap'), Map<String,String>.class);
            this.setSearchingChildObjects = (Set<String>)System.JSON.deserialize(mapDataJSON.get('searchingChildObjectsSet'), Set<String>.class);
        }
        //CHaRM R5: To get the start and end date
        if(this.strQuery != null)
            this.getStartAndEndDate();
    }    
    /*
    * @Constructor  : DynamicTicketReviewSearchSequenceBatch.
    * @Description  : To execute logic upon class initialization.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : String strQuery, String strTicketReviewId, Boolean isParent,
                      Map<String,String> mapChildObjectAPIAndTicketField,
                      Map<String,String> mapChildObjectAPINameAndQuery, Set<String> setobjectsIncludedInSearch.
    */
    public DynamicTicketReviewSearchSequenceBatch(List<Map<String,String>> lstJSONDataToBatch, Integer intCounterIndex, DateTime daterangeStart){
        this.intCounterIndex = intCounterIndex;
        this.lstJSONDataToBatch = lstJSONDataToBatch;
        Map<String,String> mapDataJSON = lstJSONDataToBatch[intCounterIndex];
        //CHaRM-R5: Added date range and to include in the batch query and added StartDate and EndDate
        dateRange = (Integer)CHaRM_Misc_Settings__c.getOrgDefaults().TicketReviewSearchRange__c;        
        startDate = daterangeStart;
        endDate = daterangeStart.addMonths(dateRange);
        
        for(String strKey : mapDataJSON.keySet()){
            this.isParent = mapDataJSON.get('isParent') == 'TRUE' ? true : false;
            this.strQuery = mapDataJSON.get('query');
            this.strTicketReviewId = mapDataJSON.get('ticketReviewId');
            if(!this.isParent){
               this.strQuery = 'SELECT Id FROM ACCOUNT'; // Dummy Query
                this.setChildQueryOnly = (Set<String>)System.JSON.deserialize(mapDataJSON.get('childObjQuery'), Set<String>.class);
            }
            this.setobjectsIncludedInSearch = (Set<String>)System.JSON.deserialize(mapDataJSON.get('objectsIncludedInSearchSet'), Set<String>.class);
            this.mapChildObjectAPIAndTicketField = (Map<String,String>)System.JSON.deserialize(mapDataJSON.get('childObjectAPIAndTicketFieldMap'), Map<String,String>.class);
            this.mapChildObjectAPINameAndQuery = (Map<String,String>)System.JSON.deserialize(mapDataJSON.get('childObjectAPINameAndQueryMap'), Map<String,String>.class);
            this.setSearchingChildObjects = (Set<String>)System.JSON.deserialize(mapDataJSON.get('searchingChildObjectsSet'), Set<String>.class);
        }
    }    
    //CHaRM-R5: Start
    /*
    * @Method       : getStartAndEndDate.
    * @Description  : To get the start and end date to process in the batch
    * @Invoke       : From DynamicTicketReviewSearchSequenceBatch class.
    */
    public void getStartAndEndDate(){
        List<CMPL123CME__Complaint__c> ticketList = new List<CMPL123CME__Complaint__c>();
        if(strQuery.contains('LIMIT')){
            String startDateQuery = strQuery + ' ORDER BY Createddate asc LIMIT 1';
            ticketList = Database.query(startDateQuery);            
            if(ticketList.size() > 0)
            {
                startDate = ticketList[0].createdDate;
                endDate = startDate.addMonths(dateRange);
            }
        }
    }//CHaRM -R5: End

    /*
    * @Method       : start.
    * @Description  : To collect the records to pass to the execute method.
    * @Invoke       : From DynamicTicketReviewSearchSequenceBatch class.
    * @Return       : Database.QueryLocator.
    * @Params       : Database.BatchableContext BC.
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        if(startDate != null && endDate != null)
            //CHaRM R5: Added the created date and end date to the query to get the queried records
            strQuery = strQuery + ' and createdDate >= '+ startDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' and createdDate <= '+ endDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        return Database.getQueryLocator(strQuery);
        
    }
    /*
    * @Method       : execute.
    * @Description  : To do the required processing for each chunk of data.
    * @Invoke       : From DynamicTicketReviewSearchSequenceBatch class.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC, List<sObject> lstRecords.
    */
    global void execute(Database.BatchableContext BC, List<sObject> lstRecords) {                
        if(isParent){
            processParent(lstRecords);
        }else{
            processChild();
        }
        //CHaRM-R5-Start: Add the below code to update Saerch status field with 'In Progress' once the Batch Executes
        string batchStatus = 'In Progress';
        Ticket_Review__c objTicketReview = New Ticket_Review__c(Id = strTicketReviewId,Search_Status__c = batchStatus);
        update objTicketReview;
        //CHaRM-R5-End
    }

    /*
    * @Method       : finish
    * @Description  : To run DynamicTicketReviewSearchSequenceBatch execution.
    * @Invoke       : From DynamicTicketReviewSearchSequenceBatch class.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC.
    */
    global void finish(Database.BatchableContext BC) {
        //CHaRM-R5: Added Enddate in the condition to loop the batch and added condition to update Search Status field with Completed status if the batch is completed and
        //populate the Search status field with Failed status if the batch job is failed.
        if(endDate != null && endDate < Date.today())
        {
            ID jobID = Database.executeBatch(new DynamicTicketReviewSearchSequenceBatch(lstJSONDataToBatch, intCounterIndex,endDate),150);
        }
        else if(intCounterIndex < (lstJSONDataToBatch.size() - 1)){
            ID jobID = Database.executeBatch(new DynamicTicketReviewSearchSequenceBatch(lstJSONDataToBatch, intCounterIndex+1),150);
            
        }else{
            String jobStatus = 'Completed';
            
            AsyncApexJob asyncApexObj = [Select Id, Status, CompletedDate, ExtendedStatus from AsyncApexJob Where Id =: BC.getJobId()];
            
            if(asyncApexObj != null){
                if(asyncApexObj.Status == 'Failed'){
                    jobStatus = 'Failed';
                } 
                
                if(asyncApexObj.ExtendedStatus != null && asyncApexObj.ExtendedStatus.Contains('error'))
                {
                    jobStatus = 'Failed';
                }
            }  
            
            Ticket_Review__c objTicketReview = New Ticket_Review__c(Id = strTicketReviewId, Search_Status__c = jobStatus);
            update objTicketReview;

            this.notifyUserOnComplition(BC.getJobId());
        }
    }

    /*
    * @Method       : processParent.
    * @Description  : This method is to process Complaint records and to insert Ticket_Search_Result__c records.
    * @Invoke       : From DynamicTicketReviewSearchSequenceBatch class.
    * @Return       : N/A.
    * @Params       : List<sObject> lstRecords.
    */
    private void processParent(List<sObject> lstRecords){
        Schema.sObjectType objsObjectType = Schema.CMPL123CME__Complaint__c.getSObjectType();
        List<Ticket_Search_Result__c> lstTicketSearchResults = new List<Ticket_Search_Result__c>();

        //Optimization related to Defect 1534 BEGIN
        Ticket_Search_Result__c tmpTSR = new Ticket_Search_Result__c();
        //Optimization related to Defect 1534 END
        for(Sobject sObjRecord : lstRecords){
            if(sObjRecord.getSobjectType() == objsObjectType){
                Ticket_Search_Result__c objTicketSearchResult = processComplaintAndChildsData(sObjRecord, strTicketReviewId);
                //Defect 1534 fix. 'objTicketSearchResult != new Ticket_Search_Result__c()' changed to 'objTicketSearchResult != tmpTSR'
                if(objTicketSearchResult != tmpTSR){
                    lstTicketSearchResults.add(objTicketSearchResult);
                }
            }
        }

        if(lstTicketSearchResults.size() > 0){
            upsert lstTicketSearchResults Unique_Identifier__c;
        }
    }

    /*
    * @Method       : processChild.
    * @Description  : This method is to process child only records which are related to Complaint.
    * @Invoke       : From DynamicTicketReviewSearchSequenceBatch class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private void processChild(){
        Set<ID> ticketsIdSet = new Set<ID>();
        Set<ID> finalticketIdSet = new Set<ID>();
        integer i = 0;
        for(String childObjQuery : setChildQueryOnly){
            for(Sobject sobj : Database.query(childObjQuery)){
                String sobjectType = String.valueOf(sobj.getSobjectType());
                if(mapChildObjectAPIAndTicketField.size() > 0 && mapChildObjectAPIAndTicketField.containsKey(sobjectType)){
                    String ticketId = String.valueOf(sobj.get(mapChildObjectAPIAndTicketField.get(sobjectType)));
                    if(String.isNotBlank(ticketId)){
                        if(i == 0 ){
                            ticketsIdSet.add(ticketId);
                        }else{
                            if(ticketsIdSet.contains(ticketId)){
                                finalticketIdSet.add(ticketId);
                            }
                        }
                    }
                }
            }
            i++;
        }
        if(setChildQueryOnly.size() == 1){
            finalticketIdSet.addAll(ticketsIdSet);
        }
        if(finalticketIdSet.size() > 0){
            createComplaintAndChildsQuery(finalticketIdSet, mapChildObjectAPINameAndQuery);

        }
    }

    /*
    * @Method       : createComplaintAndChildsQuery.
    * @Description  : This method creates the query bases on childs ticket id set.
    * @Invoke       : From DynamicTicketReviewSearchSequenceBatch class.
    * @Return       : N/A.
    * @Params       : Set<ID> ticketsIdSet, Map<String,String> childObjectAPINameAndQueryMap.
    */
    private void createComplaintAndChildsQuery(Set<ID> ticketsIdSet, Map<String,String> childObjectAPINameAndQueryMap){





        
        if(ticketsIdSet.size() > 0){
            List<Id> lstTicketIds = new List<Id>();
            lstTicketIds.addAll(ticketsIdSet);
            String query = '';
            if(childObjectAPINameAndQueryMap.size() > 0 && childObjectAPINameAndQueryMap.containsKey('TSB__c')){
                String tsbQuery = (childObjectAPINameAndQueryMap.get('TSB__c')).replace('TSB__c','TSBs__r');
                query += '('+ tsbQuery+'),';
            }else{
                query += '('+ DynamicTicketReviewSearchController.createTSBQuery() +'),';
            }
            if(childObjectAPINameAndQueryMap.size() > 0 && childObjectAPINameAndQueryMap.containsKey('CMPL123CME__MEDDEV__c')){
                String meddevQuery = (childObjectAPINameAndQueryMap.get('CMPL123CME__MEDDEV__c')).replace('CMPL123CME__MEDDEV__c','CMPL123CME__MEDDEV__r');
                query += '('+ meddevQuery +'),';
            }else{
                query += DynamicTicketReviewSearchController.createMeddevQuery() + ',';

            }
            if(childObjectAPINameAndQueryMap.size() > 0 && childObjectAPINameAndQueryMap.containsKey('CMPL123CME__EMDR__c')){
                String eMDRQuery = (childObjectAPINameAndQueryMap.get('CMPL123CME__EMDR__c')).replace('CMPL123CME__EMDR__c','CMPL123CME__EMDR__r');
                query += '('+ eMDRQuery +'),';
            }else{
                query +=  DynamicTicketReviewSearchController.createEMDRQuery() + ',';
            }
            // @Juneid 22 June 2021, Added for EUMIR 
            if(childObjectAPINameAndQueryMap.size() > 0 && childObjectAPINameAndQueryMap.containsKey('CMPL123CME__EU_MIR__c')){
              
                String eUMIRQuery = (childObjectAPINameAndQueryMap.get('CMPL123CME__EU_MIR__c')).replace('CMPL123CME__EU_MIR__c','CMPL123CME__EU_MIR__r');
                query += '('+ eUMIRQuery +'),';
            }else{
                query +=  DynamicTicketReviewSearchController.createEUMIRQuery() + ',';
            } //
            query = query.removeEnd(',');
            query = DynamicTicketReviewSearchController.createSelectClause('CMPL123CME__Complaint__c','TicketReview',new List<String>(), setobjectsIncludedInSearch, mapChildObjectAPIAndTicketField)+','+query+ ' FROM CMPL123CME__Complaint__c WHERE ID IN : ticketsIdSet';
           
            processParent(Database.query(query));
        }
    }

    /*
    * @Method       : processComplaintAndChildsData.
    * @Description  : This method generate Ticket_Search_Result__c records.
    * @Invoke       : From DynamicTicketReviewSearchSequenceBatch class.
    * @Return       : Ticket_Search_Result__c.
    * @Params       : Sobject complaintAndChildData, String ticketReviewId.
    */
    private Ticket_Search_Result__c processComplaintAndChildsData(Sobject complaintAndChildData, String ticketReviewId){
       
        CMPL123CME__Complaint__c ticketRecord = (CMPL123CME__Complaint__c)complaintAndChildData;
        Ticket_Search_Result__c ticketSearchResultData = new Ticket_Search_Result__c();
        Boolean processSearchData = false;
        if(setSearchingChildObjects != null && setSearchingChildObjects.size() > 0){
            for(String childObject : setSearchingChildObjects){
                if(ticketRecord.getSObjects(childObject) != null && ticketRecord.getSObjects(childObject).size() > 0){
                    processSearchData = true;
                }else{
                    processSearchData = false;
                    break;
                }
            }
            if(processSearchData){
                ticketSearchResultData = createTicketSearchResult(ticketRecord,ticketReviewId);
            }
        }else{
            ticketSearchResultData = createTicketSearchResult(ticketRecord,ticketReviewId);
        }

        return ticketSearchResultData;
    }

    /*
    * @Method       : createTicketSearchResult.
    * @Description  : This method generate Ticket_Search_Result__c records.
    * @Invoke       : From DynamicTicketReviewSearchSequenceBatch class.
    * @Return       : Ticket_Search_Result__c.
    * @Params       : CMPL123CME__Complaint__c ticketData, String ticketReviewId.
    */
    private Ticket_Search_Result__c  createTicketSearchResult (CMPL123CME__Complaint__c ticketData, String ticketReviewId){
      
        Ticket_Search_Result__c ticketSearchResult = new Ticket_Search_Result__c();
        ticketSearchResult.Ticket__c = (String)ticketData.get('Id');
        ticketSearchResult.Is_Ticket_Adverse_Event__c = (String)ticketData.get('Was_an_Adverse_Event_Identified__c');
        ticketSearchResult.Ticket_Review__c = ticketReviewId;
        ticketSearchResult.Submission_Information__c = '';
        ticketSearchResult.Unique_Identifier__c = ticketReviewId+'-'+(String)ticketData.get('Id');
        //Optimization related to Defect 1534 BEGIN
        String tmpFAMandatoryTSBNumber = '';
        for (TSB__c tsb : ticketData.TSBs__r) {
            if (tsb.TSB_Type__c != null && tsb.TSB_Type__c.containsIgnoreCase('FA Mandatory')) {
                tmpFAMandatoryTSBNumber += tsb.Name + (tsb.TSB_Description__c != null ? '~'+tsb.TSB_Description__c : '') +'   \r\n';
            }
        }
        String tmpSubmissionInformation = '';
        for(CMPL123CME__MEDDEV__c meddevRecord : ticketData.CMPL123CME__MEDDEV__r){
            tmpSubmissionInformation += (meddevRecord.CMPL123CME__Type_of_Report__c != null ? meddevRecord.CMPL123CME__Type_of_Report__c+'~' : '') +
                +'MDI'+ '~'+meddevRecord.CMPL123_WF_Status__c+'  \r\n';
        }
        for(CMPL123CME__EMDR__c emdrRecord : ticketData.CMPL123CME__EMDR__r){
            tmpSubmissionInformation += emdrRecord.RecordType.Name +'~'+'eMDR'+'~'+
                emdrRecord.CMPL123CME__CMPL123_WF_Status__c+
                (emdrRecord.Classification__c != null ? '~'+ emdrRecord.Classification__c : '')+'  \r\n';
        }

        //@Juneid 22 June 2021, Added for EUMIR Ticket Search
        for(CMPL123CME__EU_MIR__c euMirRecord : ticketData.CMPL123CME__EU_MIR__r){
            tmpSubmissionInformation += (euMirRecord.CMPL123CME__Type_of_Report__c != null ? euMirRecord.CMPL123CME__Type_of_Report__c+'~' : '') +
                +'EUMIR'+ '~'+euMirRecord.CMPL123_WF_Status__c+'  \r\n';
        }
       
        ticketSearchResult.Submission_Information__c = tmpSubmissionInformation;
        ticketSearchResult.Total_Number_of_MDI__c = ticketData.CMPL123CME__MEDDEV__r.size();
        ticketSearchResult.Total_Number_of_eMDR__c = ticketData.CMPL123CME__EMDR__r.size();
        //@Juneid 17 June 2021
        ticketSearchResult.Total_Number_of_EU_MIR__c = ticketData.CMPL123CME__EU_MIR__r.size();
        
        ticketSearchResult.FA_Mandatory_TSB_number__c = tmpFAMandatoryTSBNumber;
        //Optimization related to Defect 1534 END
        return ticketSearchResult;
    }
    //@Juneid 3 June 2021, Tikcket Search Email Notification
    private void notifyUserOnComplition(Id jobId){ 
       
        Set<Id> createdByIdSet = new Set<Id>();    
        
        List<Ticket_Review__c> tickekReviewRecords = [Select Id, Name, Quality_Assignee_Name__r.Name,Quality_Assignee_Name__r.Email,
                                                      Medical_Assignee_Name__r.Name,medical_Assignee_Name__r.Email,RecordType.Name,Search_Frequency__c
                                                      From Ticket_Review__c
                                                      Where RecordTypeId =: AspenConstants.Recurrence_Search_RecordType_Id AND Id = : this.strTicketReviewId];
      
        AsyncApexJob asyncApexObj = [Select Id ,Status, CompletedDate from AsyncApexJob Where Id =: jobId];
        
        String fileRow = '';
        
        Map<Id,String> ticketReviewRecordMap = new Map<Id,String>();
        // Logic to create csv (Attachement file) to sent Email. 
        
        for(Ticket_Review__c tickekReviewObject: tickekReviewRecords){
            
            String medicalAssigneeName = 'N/A';
            if(tickekReviewObject.Medical_Assignee_Name__r.Name != null){
                medicalAssigneeName = tickekReviewObject.Medical_Assignee_Name__r.Name;
            }
            fileRow = '';
            fileRow = fileRow +','+ tickekReviewObject.Name;
            fileRow = fileRow +','+ tickekReviewObject.Quality_Assignee_Name__r.Name;
            fileRow = fileRow +','+ medicalAssigneeName;
            fileRow = fileRow +','+ tickekReviewObject.RecordType.Name;
            fileRow = fileRow +','+ tickekReviewObject.Search_Frequency__c;  
            fileRow = fileRow +','+ asyncApexObj.CompletedDate.formatGMT('MM/dd/yyyy hh:mm zz');
            fileRow = fileRow +','+ 'Completed'; 
            fileRow = fileRow +','+ 'No Action Required'; 
           
            
            
            
            fileRow = fileRow.replaceFirst(',','');
            
          
            ticketReviewRecordMap.put(tickekReviewObject.Id,FileRow);
                
            
        }
        
        List<Messaging.SingleEmailMessage> sendEmailList = new List<Messaging.SingleEmailMessage>();
        //CHaRM-R5: Updated the "Status" Column to "Search Status" as per IPDR 191 By Dinesh Kumar
        String csvFileToGroup = 'Name (Ticket Review Number)'+','+'Quality Assignee Name'+','+'Medical Assignee Name'+','+'Record Type'+','+'Search Frequency'+','+'Time of Success'+','+'Search Status'+','+'Action Required'+'\n'; 
        
        
        
        //Logic for send to email to record created user
        for(Ticket_Review__c tickekReviewObject: tickekReviewRecords){
            
            List<String> toAddresses = new List<String>();
            toAddresses.add(tickekReviewObject.Quality_Assignee_Name__r.Email);
            if(tickekReviewObject.medical_Assignee_Name__r.Email != Null){
                  toAddresses.add(tickekReviewObject.medical_Assignee_Name__r.Email);
            }
          
            
            Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
           
            String generatedCSVFile = csvFileToGroup;
            
            generatedCSVFile = generatedCSVFile + ticketReviewRecordMap.get(tickekReviewObject.Id);
            csvFileToGroup = csvFileToGroup + ticketReviewRecordMap.get(tickekReviewObject.Id);
            Blob csvBlob = blob.valueOf(generatedCSVFile);
            String csvName = 'Ticket Review Success Information.csv';
            csvAttachment.setFileName(csvName);
            csvAttachment.setBody(csvBlob);
            if(toAddresses.size() > 0){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(toAddresses);
                mail.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});
                mail.setSubject('Ticket Review Success Information');
                mail.setPlainTextBody('Hi,\n\n'+tickekReviewObject.Name+' Ticket Review Search is Successfully Completed.');
                sendEmailList.add(mail);
            }
           
        }       

        // Sent mail 
        Messaging.sendEmail(sendEmailList);
    }
}