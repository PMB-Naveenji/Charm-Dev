/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : DynamicTicketReviewSearchController.
* @Why   : This class is used to search the complaint records based on search criteria and to create Ticket_Search_Result__c records.
* @When  : 05-MAR-2019.
* @Where : From DynamicTicketReviewSearch page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                 Modification ID          Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    05-MAR-2019          Work ID / Case ID        Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    07-MAR-2019          Work ID / Case ID        Updated.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020          Code Audit               Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    20-OCT-2020          HC #40/CHARM-3336        Removed wrong null checking.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    24-NOV-2020          HC #86/CHARM-3512        Fixed invalid parsing in 'contains in' case.
* --------------------------------------------------------------------------------------------------------------------------------------
* Neeraj                   25-JUN-2021          FRS-700-02               Added EU_MIR for Ticket Search 
* --------------------------------------------------------------------------------------------------------------------------------------
* Larry Resnik             21-JUL-2022          IPDR 191                 Replace hard-coded batch-chunking size with a configurable solution
* --------------------------------------------------------------------------------------------------------------------------------------
* Dinesh kumar             20-JUL-2024          CHARM-R5/IPDR-191        Updated the method "createSelectClause"
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class DynamicTicketReviewSearchController {
    // Determine this limit from online documentation since it is not stored in System.Limits
    // 21-JUL-2022 Larry: Defined
    public static final Integer LIMIT_BATCHABLE_SIZE = 200;
    public static final String CHARM_SETTING_MDT_NAME = 'Default';
    public static Integer batchSize {
        private set;
        get {
            if (batchSize == null) {
                CHaRM_Settings__mdt settings = [
                    SELECT Id, MasterLabel, Ticket_Review_Search_Batch_Size__c
                    FROM CHaRM_Settings__mdt
                    WHERE MasterLabel = :CHARM_SETTING_MDT_NAME
                    LIMIT 1
                ];
                // Use a temp variable or else the getter will re-reference the null
                Integer temp = settings.Ticket_Review_Search_Batch_Size__c.intValue();
                temp = Math.min(Math.max(temp, 1), LIMIT_BATCHABLE_SIZE);
                batchSize = temp;
            }
            return batchSize;
        }
    }
    
    // This set contains the objects included in the searching.
    public static Set<String> objectsIncludedInSearchSet;
    
    // Ticket review Id
    public static ID ticketReviewId;
    
    // It will stores the child queries
    public static Set<String> childQueriesSet;
    
    // This map stores the key as child object API and value as related ticket api name
    public static Map<String,String> childObjectAPIAndTicketFieldMap;
    
    // This map stores the child object api name as a key and query as a value
    public static Map<String,String> childObjectAPINameAndQueryMap;
    
    // To show each sesarch filter return record count
    public transient static Map<String,Integer> mapShowSearchFilterRecordsReturnCount {get; set;}
    
    // To wait till all related batch jobs completes
    public static Boolean isWait {get; set;}
    
    // To confirm to create Ticket_Search_Result__c records from batch class
    public static Boolean isConfirmSearch {get; set;}
    
    // To store batch Ids related to this ticket review record
    private String strStoreBatchIds = '';
    
    /**
    * @Method       : recheckBatchCompletion
    * @Invoke       : From DynamicTicketReviewSearch Page, actionPoller
    * @Description  : This method is to check batch completion, if completed then show search page, else recheck after sometime.
    * @Return       : PageReference
    * @Params       : N/A
    **/     
    public PageReference recheckBatchCompletion() {
        if(String.isNotBlank(strStoreBatchIds)){
            mapShowSearchFilterRecordsReturnCount = new Map<String,Integer>(); 
            Set<String> setBatchIds = New Set<String>(strStoreBatchIds.split(','));
            Set<String> setBatchStatuses = New Set<String>{'Holding','Queued','Preparing','Processing'};
            List<AsyncApexJob> lstAsyncApexJobs = [SELECT Id FROM AsyncApexJob WHERE Id IN: setBatchIds AND status IN: setBatchStatuses AND JobType = 'BatchApex'];
            if(lstAsyncApexJobs == null || lstAsyncApexJobs.size() == 0) {
                isWait = false;
                return fetchQueryResults();
            }else {
                isWait = true;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm,Label.Ticket_Search_Please_wait));
                return null;
            } 
        }
        isWait = false;
        return fetchQueryResults();
    }
    
    /**
    * @Method       : fetchQueryResults
    * @Invoke       : From DynamicTicketReviewSearch Page (onload) and recheckBatchCompletion method
    * @Description  : This method process the tickets and creates the ticket search results
    * @Return       : PageReference
    * @Params       : N/A
    **/     
    public pagereference fetchQueryResults(){
        isWait = false;
        mapShowSearchFilterRecordsReturnCount = new Map<String,Integer>(); 
        strStoreBatchIds = '';
        List<Map<String,String>> lstJSONDataToBatch = New List<Map<String,String>>();
        try{
            ticketReviewId = ApexPages.currentPage().getParameters().get('Id');
            Search_Log__c searchlog = new Search_Log__c();
            Map<String,String> mapSearchCriteria = new Map<String,String>();
            String userReadableSearchCriteria = '';
            //Added, W-000352
            Boolean activeTask = true;
            if(String.isNotBlank(ticketReviewId)){
                // collecting search criteria and existing tickets for the particular ticket review
                for(Ticket_Review__c ticketReview 
                    : [SELECT Id,Status__c,Number_of_tickets__c,Pending_Batch_Jobs__c,
                       (SELECT Id,Criteria__c,Search_Criteria__c FROM Searches__r)
                       FROM Ticket_Review__c 
                       WHERE Id =: ticketReviewId ]){
                           
                           //Added, W-000352
                           if(ticketReview.Status__c == 'Inactive'){
                               activeTask = false;
                               ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,Label.Ticket_Search_Inactive_Ticket_Review));
                               return null;
                           }
                           
                           // Only one record
                           if(ticketReview.Pending_Batch_Jobs__c != null && String.isNotBlank(ticketReview.Pending_Batch_Jobs__c)){
                               strStoreBatchIds = ticketReview.Pending_Batch_Jobs__c;
                           }
                           
                           //Added, W-000352 condition
                           if(activeTask == true){
                               for(Search__c search : ticketReview.Searches__r){
                                   mapSearchCriteria.put(search.Search_Criteria__c,search.Criteria__c);
                                   String condition = ') AND ';
                                   if(search.Criteria__c != null && search.Criteria__c.contains(condition)){
                                       userReadableSearchCriteria += '('+search.Criteria__c +') OR ';
                                   }else{
                                       userReadableSearchCriteria += search.Criteria__c +' OR ';
                                   }
                               }
                           }
                       }
                if(String.isNotBlank(strStoreBatchIds)){
                    Set<String> setBatchIds = New Set<String>(strStoreBatchIds.split(','));
                    Set<String> setBatchStatuses = New Set<String>{'Holding','Queued','Preparing','Processing'};
                    List<AsyncApexJob> lstAsyncApexJobs = [SELECT Id FROM AsyncApexJob WHERE Id IN: setBatchIds AND status IN: setBatchStatuses AND JobType = 'BatchApex'];

                    if (lstAsyncApexJobs.size() != 0) { // Def HC #40/CHARM-3336: removed wrong condition (lstAsyncApexJobs - always not null)
                        isWait = true;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm,Label.Ticket_Search_Please_wait));
                        return null;
                    } 
                }
                
                strStoreBatchIds = '';
                //Added, W-000352 Condition
                if(activeTask == true) {
                    for(String searchCriteria : mapSearchCriteria.keySet()){
                        Map<String,String> mapQueryRelatedData = New Map<String,String>();
                        Map<String,Set<String>> queryMap = createSearchQuery(searchCriteria,'TicketReview',new List<String>());
                        String query;
                        for(String queryData : queryMap.get('query')){
                            query = queryData;   
                        }
                        if(String.isNotBlank(query)){
                            if(query.contains('FROM') && isConfirmSearch != true){
                                List<String> lstSplitQueryFROM = query.split('FROM'); 
                                if(lstSplitQueryFROM.size() > 0){
                                    mapShowSearchFilterRecordsReturnCount.put(mapSearchCriteria.get(searchCriteria), Database.countQuery('SELECT count() FROM '+lstSplitQueryFROM[lstSplitQueryFROM.size() - 1]));
                                }
                            }
                            
                            if(isConfirmSearch == true){
                                mapQueryRelatedData.put('query',query);
                                mapQueryRelatedData.put('isParent','TRUE');
                                mapQueryRelatedData.put('ticketReviewId',ticketReviewId);
                                mapQueryRelatedData.put('objectsIncludedInSearchSet',JSON.serialize(queryMap.get('objectsIncludedInSearchSet')));
                                mapQueryRelatedData.put('searchingChildObjectsSet',JSON.serialize(queryMap.get('searchingChildObjectsSet')));
                                mapQueryRelatedData.put('childObjectAPIAndTicketFieldMap',JSON.serialize(childObjectAPIAndTicketFieldMap));
                                mapQueryRelatedData.put('childObjectAPINameAndQueryMap',JSON.serialize(childObjectAPINameAndQueryMap));
                            }
                            
                        }else{
                            // Handling only child object queries(without complaint)
                            for(String childObjQuery : childQueriesSet){
                                if(childObjQuery.contains('FROM') && isConfirmSearch != true){
                                    List<String> lstSplitQueryFROM = childObjQuery.split('FROM'); 
                                    if(lstSplitQueryFROM.size() > 0){
                                        mapShowSearchFilterRecordsReturnCount.put(mapSearchCriteria.get(searchCriteria),Database.countQuery('SELECT count() FROM '+lstSplitQueryFROM[lstSplitQueryFROM.size() - 1]));
                                    }
                                }
                            }
                            
                            if(isConfirmSearch == true){
                                mapQueryRelatedData.put('query','');
                                mapQueryRelatedData.put('childObjQuery',JSON.serialize(childQueriesSet));
                                mapQueryRelatedData.put('isParent','FALSE');
                                mapQueryRelatedData.put('ticketReviewId',ticketReviewId);
                                mapQueryRelatedData.put('objectsIncludedInSearchSet',JSON.serialize(queryMap.get('objectsIncludedInSearchSet')));
                                mapQueryRelatedData.put('searchingChildObjectsSet',JSON.serialize(queryMap.get('searchingChildObjectsSet')));
                                mapQueryRelatedData.put('childObjectAPIAndTicketFieldMap',JSON.serialize(childObjectAPIAndTicketFieldMap));
                                mapQueryRelatedData.put('childObjectAPINameAndQueryMap',JSON.serialize(childObjectAPINameAndQueryMap));
                            }
                        }
                        
                        if(!mapQueryRelatedData.isEmpty()){
                           lstJSONDataToBatch.add(mapQueryRelatedData); 
                        }
                        
                    }

                    if(lstJSONDataToBatch.size() > 0 && isConfirmSearch == true){
                        // 21-JUL-2022 Larry: Replace hard-coded 150 with a configurable solution
                        ID jobID = Database.executeBatch(
                            new DynamicTicketReviewSearchSequenceBatch(lstJSONDataToBatch, 0), batchSize);
                        strStoreBatchIds = jobID;
                        
                        // This is the only DML from this class
                        if(String.isNotBlank(strStoreBatchIds) && isConfirmSearch == true){
                            searchlog.Ticket_Review__c = ticketReviewId;
                            searchlog.Search_Date_Time__c = DateTime.now();
                            searchlog.Search_Performed_By__c = UserInfo.getName();
                            searchlog.Search_Criteria__c = userReadableSearchCriteria.removeEnd(' OR ');
                            
                            insert searchlog;
                            
                            Ticket_Review__c objTicketReview = New Ticket_Review__c(Id = ticketReviewId, Pending_Batch_Jobs__c = strStoreBatchIds);
                            update objTicketReview;
                            
                        }
                    }
                    
                    if(mapSearchCriteria.isEmpty()){
                        //Added, W-000402 - If there is no Search record
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,Label.Ticket_Search_No_Search_Criteria));
                        return null;
                    }
                    
                    if(isConfirmSearch == true){
                        isWait = true;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm,Label.Ticket_Search_Please_wait));
                    }
                    isConfirmSearch = false;

                }else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,Label.Ticket_Search_Inactive_Ticket_Review));
                    return null; 
                }
            }
        }catch(Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
            return null;
        }
        return null;
    }
    
    /**
    * @Method       : createSearchQuery
    * @Invoke       : From fetchQueryResults Method
    * @Description  : Constrcting the query string based on the search criteria and it is in the form of JSON string.
    * @Return       : Map<String,Set<String>>
    * @Params       : String searchCriteriaJSON,String identifier,List<String> ticketFieldsList
    **/    
    public static Map<String,Set<String>> createSearchQuery(String searchCriteriaJSON,String identifier,List<String> ticketFieldsList){
        String query;
        Map<String,Set<String>> resultMap = new Map<String,Set<String>>();
        Set<String> searchingChildObjectsSet = new Set<String>();
        if(String.isNotBlank(searchCriteriaJSON)){
            String fromClause = 'FROM ';
            String WhereClause = 'WHERE ';
            String mainQuery;
            List<String> innerQueryList = new List<String>();
            objectsIncludedInSearchSet = new Set<String>();
            childObjectAPIAndTicketFieldMap = new Map<String,String>();
            childObjectAPINameAndQueryMap = new Map<String,String>();
            childQueriesSet = new Set<String>();
            
            
            // This map stores the object api name as a key and necessary data(for creating query) as a value
            // Eg : {CMPL123CME__Complaint__c=({SequenceNumber=1, childRelationshipName=TSBs, fieldAPIName=Quality_Directive_Number__c, operatorSign is =, value=123}, 
            //                                 {SequenceNumber=2, childRelationshipName=TSBs, fieldAPIName=Receipt_Date__c, operatorSign is >, value=2016-12-27T21:54:44.000+0000}, 
            //                                 {logic=1 AND 2})
            //       }
            Map<String,Object> searchCriteriaLabelAndDataMap = (Map<String,Object>)JSON.deserializeUntyped(searchCriteriaJSON);
            
            objectsIncludedInSearchSet.addAll(searchCriteriaLabelAndDataMap.keySet());
            // Defining the Inner class(searchingObjectInnerController) list
            List<searchingObjectInnerController> searchingObjectInnerControllerList = new List<searchingObjectInnerController>();
            
            for(String searchObjectAPIName : searchCriteriaLabelAndDataMap.keySet()){
                searchingObjectInnerController searchingObjectInnerRec = new searchingObjectInnerController();
                searchingObjectInnerRec.objectAPIName = searchObjectAPIName; 
                
                // Defining the Innerclass(searchingDataInnerController) list
                List<searchingDataInnerController> searchingDataList = new List<searchingDataInnerController>();
                
                // collecting each object search criteria as a inner class record and adding to the list of 
                // searchingObjectInnerController data
                for(Object fieldsDataInfo : (List<Object>)searchCriteriaLabelAndDataMap.get(searchObjectAPIName)){
                    Map<String,Object> fieldLableAndValueMap = (Map<String,Object>)fieldsDataInfo;
                    if(fieldLableAndValueMap.containsKey('logic')){
                        searchingObjectInnerRec.logic = (String)fieldLableAndValueMap.get('logic');
                        searchingObjectInnerRec.relatedTicketFieldAPI = (String)fieldLableAndValueMap.get('relatedTicketFieldAPI');
                        searchingObjectInnerRec.relationshipName = (String)fieldLableAndValueMap.get('relationshipName');
                    }else{
                        searchingDataInnerController searchingDataInnerControllerRec = new searchingDataInnerController();
                        searchingDataInnerControllerRec.fieldAPIName = (String)fieldLableAndValueMap.get('fieldAPIName');
                        searchingDataInnerControllerRec.operator = (String)fieldLableAndValueMap.get('operator');
                        searchingDataInnerControllerRec.operatorSign = (String)fieldLableAndValueMap.get('operatorSign');
                        searchingDataInnerControllerRec.datatype = (String)fieldLableAndValueMap.get('datatype');
                        searchingDataInnerControllerRec.value = (String)fieldLableAndValueMap.get('value');
                        searchingDataInnerControllerRec.sequenceNumber = (String)fieldLableAndValueMap.get('sequenceNumber');
                        searchingDataList.add(searchingDataInnerControllerRec);
                    }
                }
                searchingObjectInnerRec.searchingDataInnerControllerList = searchingDataList;
                searchingObjectInnerControllerList.add(searchingObjectInnerRec);
            }
            
            // This map stores the static text('mainQuery') as a key and mainQuery object name as a value
            Map<String,String> mainQueryObjectAPINameMap = new Map<String,String>();
            
            // Forming a query based on inner class records
            for(searchingObjectInnerController searchingObjInner : searchingObjectInnerControllerList){
                String whereConditions;
                Boolean isInnerObject = false;
                String objectApiName;
                
                // This map stores the key as sequence number and all the remaining data as value
                // For each object this map should be new
                Map<String,String> sequenceNumberAndDataMap = new Map<String,String>();
                if(searchingObjInner.relationshipName != 'null'){
                    childObjectAPIAndTicketFieldMap.put(searchingObjInner.objectAPIName,searchingObjInner.relatedTicketFieldAPI);
                }
                if(objectsIncludedInSearchSet.contains('CMPL123CME__Complaint__c') && objectsIncludedInSearchSet.size() > 1
                   && searchingObjInner.objectAPIName != 'CMPL123CME__Complaint__c'){
                       searchingChildObjectsSet.add(searchingObjInner.relationshipName);
                       objectApiName = searchingObjInner.relationshipName + ' ';
                       isInnerObject = true; 
                   }else{
                       objectApiName = searchingObjInner.objectAPIName + ' ';
                   }
                
                
                for(searchingDataInnerController searchingData : searchingObjInner.searchingDataInnerControllerList){
                    String value;
                    String fieldDataType = searchingData.datatype;
                    Set<String> quoteExcludeSet = new Set<String>{'DATE','DATETIME','DOUBLE','BOOLEAN'};
                        if(quoteExcludeSet.contains(fieldDataType)){
                            value = searchingData.value != '' ? searchingData.value : null;
                        }else{
                            value = '\''+String.escapeSingleQuotes(searchingData.value)+'\'';
                        }
                    
                    if (searchingData.operator.equalsIgnoreCase('contains in')) {
                        String containsInOperatorData = '';

                        //  Defect #86 fix START
                        Boolean parseByComma = searchingData.value.contains(',')
                            || (searchingData.value.contains(' ') && searchingData.value.split(' ').size() > 1);

                        if (parseByComma) {
                            List<String> parsedValues = new List<String>();

                            for (String parsedValue :searchingData.value.split(',')) {
                                parsedValues.add(parsedValue.trim());
                            }

                            containsInOperatorData = inClausify(parsedValues);
                        } else {
                            containsInOperatorData = '('+'\''+String.escapeSingleQuotes(searchingData.value.trim())+'\''+')';
                        }
                        //  Defect #86 fix END

                        sequenceNumberAndDataMap.put(searchingData.sequenceNumber, searchingData.fieldAPIName + ' ' + searchingData.operatorSign + ' '+containsInOperatorData);
                    } else {
                        // This map stores the key as sequence number and all the remaining data as value
                        // Eg : {1=Quality_Directive_Number__c='TBD' , 2=Receipt_Date__c>2016-12-27T21:54:44.000+0000....} 
                        // 1 ----> key, Quality_Directive_Number__c='TBD' ----> value 
                        sequenceNumberAndDataMap.put(searchingData.sequenceNumber, searchingData.fieldAPIName + ' ' + searchingData.operatorSign + ' ' + value);
                    }
                }
                whereConditions = createWhereClause(searchingObjInner.logic,searchingObjInner.objectAPIName,sequenceNumberAndDataMap,identifier);
                
                // Handling complaint and child objects
                if(objectsIncludedInSearchSet.contains('CMPL123CME__Complaint__c')){
                    if(isInnerObject){
                        String innerQuery = '('+createSelectClause(searchingObjInner.objectAPIName,identifier,ticketFieldsList,objectsIncludedInSearchSet, childObjectAPIAndTicketFieldMap)+ ' ' +
                            fromClause + objectApiName + WhereClause + whereConditions.trim()+')';
                        innerQueryList.add(innerQuery);
                    }else{
                        mainQuery = fromClause + objectApiName + WhereClause + whereConditions.trim();
                        mainQueryObjectAPINameMap.put('mainQuery',objectApiName.trim());
                    }
                }else{
                    // Constructing queries for child objects without complaint
                    //Updated - W-000378 - Added Limit
                    String childQuery = createSelectClause(searchingObjInner.objectAPIName,identifier,ticketFieldsList,objectsIncludedInSearchSet, childObjectAPIAndTicketFieldMap)+ ' '+ fromClause + 
                        objectApiName+ WhereClause + whereConditions.trim() + ' LIMIT ' + CMPL123__CMPL_App_Config__c.getOrgdefaults().Search_Result_Limit__c;
                    childObjectAPINameAndQueryMap.put(searchingObjInner.objectAPIName,childQuery);
                    childQueriesSet.add(childQuery);
                }
                
            }
            
            if(objectsIncludedInSearchSet.contains('CMPL123CME__Complaint__c')){
                if(innerQueryList.size() > 0 ){
                    query = createSelectClause(mainQueryObjectAPINameMap.get('mainQuery'),identifier,ticketFieldsList,objectsIncludedInSearchSet, childObjectAPIAndTicketFieldMap)+','; 
                    for(String innerQuery : innerQueryList){
                        query += innerQuery+',';     
                    }
                    query = query.removeEnd(',')+' ';
                    if(identifier.equalsIgnoreCase('TicketReview')){
                        if(!objectsIncludedInSearchSet.contains('CMPL123CME__MEDDEV__c')){
                            query += ','+createMeddevQuery();
                        }
                        if(!objectsIncludedInSearchSet.contains('CMPL123CME__EMDR__c')){
                            query += ','+createEMDRQuery();
                        }
                        //@Neeraj 25 June 2021, Ticket Search for MIR
                        if(!objectsIncludedInSearchSet.contains('CMPL123CME__EU_MIR__c')){
                            query += ','+createEUMIRQuery();
                        }
                    }
                    if(!objectsIncludedInSearchSet.contains('TSB__c')
                       && mainQueryObjectAPINameMap.get('mainQuery').equalsIgnoreCase('CMPL123CME__Complaint__c')
                       && identifier.equalsIgnoreCase('TicketReview')){
                           query += ',('+ createTSBQuery() + ') '+mainQuery;
                       }else{
                           query += mainQuery;
                       } 
                }else{
                    if(!objectsIncludedInSearchSet.contains('TSB__c') && 
                       mainQueryObjectAPINameMap.get('mainQuery').equalsIgnoreCase('CMPL123CME__Complaint__c')){
                           if(identifier.equalsIgnoreCase('TicketReview')){
                               //@Neeraj 25 June 2021, Added nee Method for Ticket Review search
                               query =  createSelectClause(mainQueryObjectAPINameMap.get('mainQuery'),identifier,ticketFieldsList,objectsIncludedInSearchSet, childObjectAPIAndTicketFieldMap) + 
                                   ',('+ createTSBQuery() + ')' + ','+createMeddevQuery() + ','+createEMDRQuery() + ','+createEUMIRQuery() +' '+mainQuery;
                           }else{
                               query =  createSelectClause(mainQueryObjectAPINameMap.get('mainQuery'),identifier,ticketFieldsList,objectsIncludedInSearchSet, childObjectAPIAndTicketFieldMap) + ' '+mainQuery;   
                           }
                       }else{
                           query =  createSelectClause(mainQueryObjectAPINameMap.get('mainQuery'),identifier,ticketFieldsList,objectsIncludedInSearchSet, childObjectAPIAndTicketFieldMap) +' '+ mainQuery;
                       }
                }
            }
            
        }
        if(identifier.equalsIgnoreCase('TicketReview')){
            resultMap.put('query',new Set<String>{query});
            resultMap.put('objectsIncludedInSearchSet',objectsIncludedInSearchSet);
            if(searchingChildObjectsSet.size() > 0)
                resultMap.put('searchingChildObjectsSet',searchingChildObjectsSet);
        }
        
        return resultMap;
    }
    
    /**
    * @Method       : inClausify
    * @Invoke       : From fetchQueryResults Method
    * @Description  : This method constructs the IN clause for the dynamic query
    * @Return       : String
    * @Params       : List<String> dataSet
    **/   
    public static String inClausify(List<String> dataSet) {
        String inClause = String.format( '(\'\'{0}\'\')', 
                                        new List<String> { String.join( new List<String>(dataSet) , '\',\'') });
        return inClause;
    }
    
    /**
    * @Method       : createSelectClause
    * @Invoke       : From fetchQueryResults Method
    * @Description  : This method constructs the SELECT clause for the dynamic query
    * @Return       : String
    * @Params       : String objectAPIName,String identifier,List<String> ticketFields, Set<String> objectsIncludedInSearchSet, Map<String,String> childObjectAPIAndTicketFieldMap
    **/
    public static string createSelectClause(String objectAPIName,String identifier,List<String> ticketFields, Set<String> objectsIncludedInSearchSet, Map<String,String> childObjectAPIAndTicketFieldMap){
        Map<String,List<String>> objectAPIAndFieldAPINamesMap = new Map<String,List<String>>();
        if(identifier.equalsIgnoreCase('TicketReview')){
            objectAPIAndFieldAPINamesMap.put('TSB__c', new List<String>{'Id','Name','TSB_Description__c','TSB_Type__c','Ticket__c'});
            objectAPIAndFieldAPINamesMap.put('CMPL123CME__Complaint__c', new List<String>{'Id',
                'Name','Was_an_Adverse_Event_Identified__c','CreatedDate'});//CHaRM-R5: Added CreatedDate field in the Select clause for Complaint object
            objectAPIAndFieldAPINamesMap.put('Product_Ticket__c', new List<string>{'Id','Name','Event_Ticket__c'});
            objectAPIAndFieldAPINamesMap.put('CMPL123CME__MEDDEV__c', new List<string>{'Id','Name',
                'CMPL123CME__Type_of_Report__c','CMPL123_WF_Status__c','CMPL123CME__Complaint__c'});
            objectAPIAndFieldAPINamesMap.put('CMPL123CME__EMDR__c', new List<string>{'Id','RecordType.Name',
                'CMPL123CME__CMPL123_WF_Status__c','Classification__c','CMPL123CME__Complaint__c'});
            //@Neeraj 25 June 2021, Added EUMIR 
            objectAPIAndFieldAPINamesMap.put('CMPL123CME__EU_MIR__c', new List<string>{'Id','Name',
                'CMPL123CME__Type_Of_Report__c','CMPL123_WF_Status__c','CMPL123CME__Complaint__c'});
            Set<String> objectsExcludedSet = new Set<String>{'TSB__c','CMPL123CME__Complaint__c','CMPL123CME__MEDDEV__c','CMPL123CME__EMDR__c','CMPL123CME__EU_MIR__c'};
                for(String searchingObject : objectsIncludedInSearchSet){
                    if(!objectsExcludedSet.contains(searchingObject)){
                        List<String> requiredFieldsList = new List<String>();
                        requiredFieldsList.add('Id');
                        if(childObjectAPIAndTicketFieldMap.size() > 0 && 
                           childObjectAPIAndTicketFieldMap.containsKey(searchingObject)){
                               requiredFieldsList.add(childObjectAPIAndTicketFieldMap.get(searchingObject));
                           }
                        objectAPIAndFieldAPINamesMap.put(searchingObject,requiredFieldsList);
                    }
                }
        }
        String selectClause = 'SELECT ';
        String fieldNames = '';
        
        if(objectAPIAndFieldAPINamesMap.containsKey(objectAPIName)){
            for(String fieldAPIName : objectAPIAndFieldAPINamesMap.get(objectAPIName)){
                fieldNames += fieldAPIName+',';
            }
            fieldNames = fieldNames.removeEnd(',');
            selectClause += fieldNames;
        }
        return selectClause;
    }
    
    /**
    * @Method       : createWhereClause
    * @Invoke       : From fetchQueryResults Method
    * @Description  : This method constructs the WHERE clause for the dynamic query
    * @Return       : String
    * @Params       : String searchLogic, String objectAPIName, Map<String,String> logicSequenceNumberAndDataMap,String identifier
    **/    
    private static String createWhereClause(String searchLogic, String objectAPIName, Map<String,String> logicSequenceNumberAndDataMap,String identifier){
        
        String whereConditionString = '';
        
        // Forming where conditions based on search logic
        // Eg : searchLogic = (1 OR 2) AND 3
        
        for(String eachCharacter : searchLogic.splitByCharacterType()){
            if(eachCharacter.isNumeric()){
                whereConditionString += logicSequenceNumberAndDataMap.containsKey(eachCharacter) ? 
                    logicSequenceNumberAndDataMap.get(eachCharacter) : '';
            }else{
                whereConditionString += eachCharacter;
            }
        }
        
        return whereConditionString;
    }
    
    /**
    * @Method       : createMeddevQuery
    * @Invoke       : From fetchQueryResults Method
    * @Description  : This method creates the query bases on childs ticket id set. 
    * @Return       : String
    * @Params       : N/A
    **/
    public static String createMeddevQuery(){
        //Defect #1534 fix BEGIN: LIMIT 200 -> ORDER BY LastModifiedDate DESC LIMIT 44
        String query = '(SELECT Id,Name,CMPL123CME__Type_of_Report__c,CMPL123_WF_Status__c ' +
                'FROM CMPL123CME__MEDDEV__r ORDER BY LastModifiedDate DESC LIMIT 44 )';
        //Defect #1534 fix END
        return query;
    }
    
    /**
    * @Method       : createEMDRQuery
    * @Invoke       : From fetchQueryResults Method
    * @Description  : This method creates the query bases on childs ticket id set. 
    * @Return       : String
    * @Params       : N/A
    **/ 
    public static String createEMDRQuery(){
        //Defect #1534 fix BEGIN: LIMIT 200 -> ORDER BY LastModifiedDate DESC LIMIT 44
        String query = '(SELECT Id,RecordType.Name,CMPL123CME__CMPL123_WF_Status__c,Classification__c '+ 
            'FROM CMPL123CME__EMDR__r ORDER BY LastModifiedDate DESC LIMIT 44 )';
        //Defect #1534 fix END
        return query;
    }
    
    //@Neeraj  25 June 2021,Ticket Search For MIR
    public static String createEUMIRQuery(){
        String query = '(SELECT Id,Name,CMPL123CME__Type_Of_Report__c,CMPL123_WF_Status__c '+ 
        'FROM CMPL123CME__EU_MIR__r ORDER BY LastModifiedDate DESC LIMIT 44)';
        return query;
    }
    
    /**
    * @Method       : createTSBQuery
    * @Invoke       : From fetchQueryResults Method
    * @Description  : This method creates the query bases on childs ticket id set. 
    * @Return       : String
    * @Params       : N/A
    **/ 
    public static String createTSBQuery(){
        //Defect #1534 fix BEGIN: LIMIT 200 -> ORDER BY LastModifiedDate DESC LIMIT 44
        String query = 'SELECT Id,Name,TSB_Type__c,TSB_Description__c,Ticket__c '+ 
            'FROM TSBs__r ORDER BY LastModifiedDate DESC LIMIT 44 ';
        //Defect #1534 fix END
        return query;
    }
    
    /** 
    *  @Class    : searchingObjectInnerController
    *  @Description   : This class is used to store the searching object related information.
    **/
    public class searchingObjectInnerController{
        public String objectAPIName;
        public String logic;
        public String objectLabel;
        public String relationshipName;
        public String relatedTicketFieldAPI;
        public List<searchingDataInnerController> searchingDataInnerControllerList;
    }
    
    /** 
    *  @Class    : searchingObjectInnerController
    *  @Description   : This class is used to store the searching fields related .
    **/
    public class searchingDataInnerController{
        public String fieldAPIName;
        public String fieldLabel;
        public String operator;
        public String operatorSign;
        public String value;
        public String sequenceNumber;
        public String datatype;
    }
}