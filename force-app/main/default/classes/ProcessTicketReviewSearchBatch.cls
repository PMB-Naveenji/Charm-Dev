/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ProcessTicketReviewSearchBatch.
* @Why   : This batch class is used to create Ticket_Search_Result__c records.
* @When  : 05-MAR-2019.
* @Where : From DynamicTicketReviewSearchController class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 05-MAR-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 07-MAR-2019         Work ID / Case ID                 Updated.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 04-JUN-2020         Code Audit                        Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                 15-JUN-2020         Code Audit                        Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 18-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 07-SEP-2020         Code Audit                        Removed empty If condition.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global class ProcessTicketReviewSearchBatch implements Database.Batchable<sObject> {


    Private String strQuery; // Query String
    Private String strTicketReviewId; // Related Ticket Review Id
    Private Boolean isParent = false; // To check the query is ( complaint and related child ) OR Child only

    Private Map<String,String> mapChildObjectAPIAndTicketField = New Map<String,String>();
    Private Map<String,String> mapChildObjectAPINameAndQuery = New Map<String,String>();
    Private Set<String> setobjectsIncludedInSearch = New Set<String>();

    /*
    * @Method       : ProcessTicketReviewSearchBatch.
    * @Description  : ProcessTicketReviewSearchBatch Constructor.
    * @Invoke       : From ProcessTicketReviewSearchBatch Class.
    * @Return       : N/A.
    * @Params       : String strQuery, String strTicketReviewId, Boolean isParent, Map<String,String> mapChildObjectAPIAndTicketField, Map<String,String> mapChildObjectAPINameAndQuery, Set<String> setobjectsIncludedInSearch.
    */
    public ProcessTicketReviewSearchBatch(String strQuery, String strTicketReviewId, Boolean isParent, Map<String,String> mapChildObjectAPIAndTicketField, Map<String,String> mapChildObjectAPINameAndQuery, Set<String> setobjectsIncludedInSearch){
        this.strQuery = strQuery;
        this.strTicketReviewId = strTicketReviewId;
        this.isParent = isParent;
        this.mapChildObjectAPIAndTicketField = mapChildObjectAPIAndTicketField;
        this.mapChildObjectAPINameAndQuery = mapChildObjectAPINameAndQuery;
        this.setobjectsIncludedInSearch = setobjectsIncludedInSearch;
    }

    /*
    * @Method       : start.
    * @Invoke       : From ProcessTicketReviewSearchBatch Class.
    * @Description  : To handle start batch job.
    * @Return       : Database.QueryLocator.
    * @Params       : Database.BatchableContext BC.
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(strQuery);
    }

    /*
    * @Method       : execute.
    * @Invoke       : From ProcessTicketReviewSearchBatch Class.
    * @Description  : To handle execute batch job.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC, List<sObject> lstRecords.
    */
    global void execute(Database.BatchableContext BC, List<sObject> lstRecords) {
        if(isParent){
            processParent(lstRecords);
        }else{
            processChild(lstRecords);
        }
    }

    /*
    * @Method       : finish.
    * @Invoke       : From ProcessTicketReviewSearchBatch Class.
    * @Description  : To handle finish batch job.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC.
    */
    global void finish(Database.BatchableContext BC) {
        // logic here
    }

    /*
    * @Method       : processParent.
    * @Invoke       : From ProcessTicketReviewSearchBatch Class.
    * @Description  : This method is to process Complaint records and to insert Ticket_Search_Result__c records.
    * @Return       : N/A.
    * @Params       : List<sObject> lstRecords.
    */
    private void processParent(List<sObject> lstRecords){
        Schema.sObjectType objsObjectType = Schema.CMPL123CME__Complaint__c.getSObjectType();
        List<Ticket_Search_Result__c> lstTicketSearchResults = new List<Ticket_Search_Result__c>();

        for(Sobject sObjRecord : lstRecords){
            if(sObjRecord.getSobjectType() == objsObjectType){
                Ticket_Search_Result__c objTicketSearchResult = processComplaintAndChildsData(sObjRecord, strTicketReviewId);
                if(objTicketSearchResult != new Ticket_Search_Result__c()){
                    lstTicketSearchResults.add(objTicketSearchResult);
                }
            }
        }

        if(lstTicketSearchResults.size() > 0){
            Schema.SObjectField sObjFieldToken = Ticket_Search_Result__c.Fields.Unique_Identifier__c;
            Database.UpsertResult[] results = Database.upsert(lstTicketSearchResults, sObjFieldToken, false);

            for (Database.UpsertResult objUpsertResult :results) {
                if (!objUpsertResult.isSuccess()) {
                    // Operation failed, so get all errors
                    for(Database.Error err : objUpsertResult.getErrors()) {
                        System.debug('error has occurred.' + err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }

    /*
    * @Method       : processChild.
    * @Invoke       : From ProcessTicketReviewSearchBatch Class.
    * @Description  : This method is to process child only records which are related to Complaint.
    * @Return       : N/A.
    * @Params       : List<sObject> lstRecords.
    */
    private void processChild(List<sObject> lstRecords){
        Set<Id> setTicketIds = new Set<Id>();
        for(Sobject sobjRecord : lstRecords){
            String sobjectType = String.valueOf(sobjRecord.getSobjectType());
            if(mapChildObjectAPIAndTicketField.size() > 0 && mapChildObjectAPIAndTicketField.containsKey(sobjectType)){
                String ticketId = String.valueOf(sobjRecord.get(mapChildObjectAPIAndTicketField.get(sobjectType)));
                setTicketIds.add(ticketId);
            }
        }

        if(setTicketIds.size() > 0){
            createComplaintAndChildsQuery(setTicketIds, mapChildObjectAPINameAndQuery);

        }
    }

    /*
    * @Method       : createComplaintAndChildsQuery.
    * @Invoke       : From ProcessTicketReviewSearchBatch Class.
    * @Description  : This method creates the query bases on childs ticket id set.
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
            query = query.removeEnd(',');
            query = DynamicTicketReviewSearchController.createSelectClause('CMPL123CME__Complaint__c','TicketReview',new List<String>(), setobjectsIncludedInSearch, mapChildObjectAPIAndTicketField)+','+query+ ' FROM CMPL123CME__Complaint__c WHERE ID IN : ticketsIdSet';
            processParent(Database.query(query));
        }
    }

    /*
    * @Method       : processComplaintAndChildsData.
    * @Invoke       : From ProcessTicketReviewSearchBatch Class.
    * @Description  : This method generate Ticket_Search_Result__c records.
    * @Return       : Ticket_Search_Result__c.
    * @Params       : Sobject complaintAndChildData, String ticketReviewId.
    */
    private Ticket_Search_Result__c processComplaintAndChildsData(Sobject complaintAndChildData, String ticketReviewId){
        CMPL123CME__Complaint__c ticketRecord = (CMPL123CME__Complaint__c)complaintAndChildData;
        Ticket_Search_Result__c ticketSearchResultData = new Ticket_Search_Result__c();
        ticketSearchResultData = createTicketSearchResult(ticketRecord,ticketReviewId);
        return ticketSearchResultData;
    }

    /*
    * @Method       : createTicketSearchResult.
    * @Invoke       : From ProcessTicketReviewSearchBatch Class.
    * @Description  : This method generate Ticket_Search_Result__c records.
    * @Return       : Ticket_Search_Result__c.
    * @Params       : CMPL123CME__Complaint__c ticketData, String ticketReviewId.
    */
    private Ticket_Search_Result__c createTicketSearchResult(CMPL123CME__Complaint__c ticketData, String ticketReviewId){
        Ticket_Search_Result__c ticketSearchResult = new Ticket_Search_Result__c();
        ticketSearchResult.Ticket__c = (String)ticketData.get('Id');
        ticketSearchResult.Is_Ticket_Adverse_Event__c = (String)ticketData.get('Was_an_Adverse_Event_Identified__c');
        ticketSearchResult.Ticket_Review__c = ticketReviewId;
        ticketSearchResult.Submission_Information__c = '';
        ticketSearchResult.Unique_Identifier__c = ticketReviewId+'-'+(String)ticketData.get('Id');
        for(TSB__c tsb : ticketData.TSBs__r){
            if(tsb.TSB_Type__c != null && tsb.TSB_Type__c.equalsIgnoreCase('Mandatory')){
                ticketSearchResult.FA_Mandatory_TSB_number__c = tsb.Name + (tsb.TSB_Description__c != null ?
                                                                            '~'+tsb.TSB_Description__c : '');
            }
        }
        ticketSearchResult.Total_Number_of_MDI__c = ticketData.CMPL123CME__MEDDEV__r.size();
        ticketSearchResult.Total_Number_of_eMDR__c = ticketData.CMPL123CME__EMDR__r.size();

        for(CMPL123CME__MEDDEV__c meddevRecord : ticketData.CMPL123CME__MEDDEV__r){
            ticketSearchResult.Submission_Information__c +=
                (meddevRecord.CMPL123CME__Type_of_Report__c != null ? meddevRecord.CMPL123CME__Type_of_Report__c+'~' : '') +
                +'MDI'+
                '~'+meddevRecord.CMPL123_WF_Status__c+'\n';

        }
        for(CMPL123CME__EMDR__c emdrRecord : ticketData.CMPL123CME__EMDR__r){
            ticketSearchResult.Submission_Information__c += emdrRecord.RecordType.Name +'~'+'eMDR'+'~'+
                emdrRecord.CMPL123CME__CMPL123_WF_Status__c+
                (emdrRecord.Classification__c != null ? '~'+ emdrRecord.Classification__c : '')+'\n';
        }
        for(CMPL123CME__EU_MIR__c euMirRecord : ticketData.CMPL123CME__EU_MIR__r){
            ticketSearchResult.Submission_Information__c += (euMirRecord.CMPL123CME__Type_of_Report__c != null ? euMirRecord.CMPL123CME__Type_of_Report__c+'~' : '') +
            +'EUMIR'+ '~'+euMirRecord.CMPL123_WF_Status__c+'  \r\n';

        }
        return ticketSearchResult;
    }
}