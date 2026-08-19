/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS5DynamicSearchController.
* @Why   : Handles all the customization involved on ADDS5DynamicSearch page.
* @When  : 23-MAR-2017.
* @Where : From ADDS5DynamicSearch page, ADDSearchController class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                   Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				  23-MAR-2017			 Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                   04-JUN-2020            Code Audit                Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                   15-JUN-2020            Code Audit                Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                   13-AUG-2020            Code Audit                Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                   07-SEP-2020            PMD Sanitizing            Added escaping of special sensitive symbols to url param.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                   07-SEP-2020            Code Audit                Added 'escapeSingleQuotes()' method call.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                   24-NOV-2020            HC #86/CHARM-3512         Fixed invalid parsing in 'contains in' case.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ADDS5DynamicSearchController {
    // This set contains the objects included in the searching.
    public static Set<String> objectsIncludedInSearchSet;

    // This set contains the complaint id's.
    public static Set<Id> ticketIdSet;

    // Ticket review Id
    public static ID ticketReviewId;

    // This set stores the ticket review existing complaint id's
    public static Set<ID> ticketReviewExistingTicketIdSet;

    // This set stores the complaint child objects
    public static Set<String> searchingChildObjectsSet;

    // It will stores the child queries
    public static Set<String> childQueriesSet;

    // This map stores the key as child object API and value as related ticket api name
    public static Map<String,String> childObjectAPIAndTicketFieldMap;

    // This map stores the child object api name as a key and query as a value
    public static Map<String,String> childObjectAPINameAndQueryMap;

    // This set stores the ticket id's
    public static Set<ID> requiredTicketIdSet;

    // This set stores the ticket id incase if the ticket review having the multple searches
    public Set<ID> multipleSearchTicketIdSet;

    public static List<Ticket_Search_Result__c> ticketSearchResultUpdateList;

    /*
    * @Method       : fetchQueryResults.
    * @Description  : To process the tickets and create the ticket search results.
    * @Invoke       : From ADDS5DynamicSearch page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void fetchQueryResults(){

        try{
            ticketSearchResultUpdateList = new List<Ticket_Search_Result__c>();
            ticketIdSet = new Set<Id>();
            ticketReviewExistingTicketIdSet = new Set<ID>();
            String ticketReviewIdParam = ApexPages.currentPage().getParameters().get('Id');
            ticketReviewId = ticketReviewIdParam != null ? ticketReviewIdParam.escapeJava() : null;
            Search_Log__c searchlog = new Search_Log__c();
            List<String> searchCriteriaList = new List<String>();
            List<ID> ticketSearchResultsIDList = new List<ID>();
            List<Search_Log__c> searchLogList = new List<Search_Log__c>();
            String userReadableSearchCriteria = '';
            //Added, W-000352
            Boolean activeTask = true;
            if(String.isNotBlank(ticketReviewId)){
                // collecting search criteria and existing tickets for the particular ticket review
                for(Ticket_Review__c ticketReview
                    : [SELECT Id,Status__c,Number_of_tickets__c,
                       (SELECT Id,Criteria__c,Search_Criteria__c FROM Searches__r),
                       (SELECT Id,Ticket__c  FROM Ticket_Searches__r
                        WHERE Ticket__c != null)
                       FROM Ticket_Review__c
                       WHERE Id =: ticketReviewId ]){
                           //Added, W-000352
                           if(ticketReview.Status__c == 'Inactive'){
                               activeTask = false;

                           }
                           //Added, W-000352 condition
                           if(activeTask == true) {
                               for(Search__c search : ticketReview.Searches__r){
                                   searchCriteriaList.add(search.Search_Criteria__c);
                                   String condition = ') AND ';
                                   if(search.Criteria__c.contains(condition)){
                                       userReadableSearchCriteria += '('+search.Criteria__c +') OR ';
                                   }else{
                                       userReadableSearchCriteria += search.Criteria__c +' OR ';
                                   }
                               }
                               for(Ticket_Search_Result__c searchResult : ticketReview.Ticket_Searches__r){
                                   ticketReviewExistingTicketIdSet.add(searchResult.Ticket__c);
                                   ticketSearchResultsIDList.add(searchResult.id);
                               }
                           }
                       }

                //Added, W-000352 Condition
                if (activeTask == true) {
                    List<Ticket_Search_Result__c> ticketSearchResultsList = new List<Ticket_Search_Result__c>();

                    // calling future method to process(MDI,eMDR and submission Information) the existing ticket search results
                    //Boolean stopFunction = true;
                    for (String searchCriteria :searchCriteriaList) {
                        Map<String, Set<String>> queryMap = createSearchQuery(searchCriteria, 'TicketReview', new List<String>());
                        String query;

                        for (String queryData :queryMap.get('query')) {
                            query = queryData;
                        }

                        if (String.isNotBlank(query)) {
                            //Added - W-000378
                            if ((System.Limits.getCpuTime() < System.Limits.getLimitCpuTime()) || (System.Limits.getQueries() < 1000)) {
                                for (Sobject sobj :Database.query(query)) {
                                    //Added - W-000378
                                    if ((System.Limits.getCpuTime() < System.Limits.getLimitCpuTime()) || (System.Limits.getQueries() < 1000)) {
                                        Schema.sObjectType objType = sobj.getSobjectType();
                                        Schema.sObjectType complaintType = Schema.CMPL123CME__Complaint__c.getSObjectType();

                                        if (objType == complaintType) {
                                            Ticket_Search_Result__c ticketSearchResultRec = processComplaintAndChildsData(sobj);

                                            if (ticketSearchResultRec != new Ticket_Search_Result__c()) {
                                                ticketSearchResultsList.add(ticketSearchResultRec);
                                                ticketReviewExistingTicketIdSet.add(ticketSearchResultRec.Ticket__c);
                                            }
                                        }
                                    } else {
                                        //Added - W-000378
                                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.General_CPU_Time_Limit));
                                        break;
                                    }
                                }
                            } else {
                                //Added - W-000378
                                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,Label.General_CPU_Time_Limit));
                                break;
                            }
                        }else{
                            // Handling only child object queries(without complaint)
                            Set<ID> ticketsIdSet = new Set<ID>();
                            Set<ID> finalticketIdSet = new Set<ID>();
                            integer i = 0;
                            for(String childObjQuery : childQueriesSet){
                                //Added - W-000378
                                if((System.Limits.getCpuTime() < System.Limits.getLimitCpuTime()) || (System.Limits.getQueries() < 1000)) {
                                    for(Sobject sobj : Database.query(childObjQuery)){
                                        //Added - W-000378
                                        if((System.Limits.getCpuTime() < System.Limits.getLimitCpuTime()) || (System.Limits.getQueries() < 1000)) {
                                            String sobjectType = String.valueOf(sobj.getSobjectType());
                                            if(childObjectAPIAndTicketFieldMap.size() > 0 && childObjectAPIAndTicketFieldMap.containsKey(sobjectType)){
                                                String ticketId = String.valueOf(sobj.get(childObjectAPIAndTicketFieldMap.get(sobjectType)));
                                                if(i == 0){
                                                    ticketsIdSet.add(ticketId);
                                                }else{
                                                    if(ticketsIdSet.contains(ticketId)){
                                                        finalticketIdSet.add(ticketId);
                                                    }
                                                }
                                            }
                                        }
                                        else {
                                            //Added - W-000378
                                            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,Label.General_CPU_Time_Limit));
                                            break;
                                        }
                                    }
                                    i++;
                                }else {
                                    //Added - W-000378
                                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,Label.General_CPU_Time_Limit));
                                    break;
                                }

                            }
                            if(childQueriesSet.size() == 1){
                                finalticketIdSet.addAll(ticketsIdSet);
                            }
                            String complaintAndChildQuery = createComplaintAndChildsQuery(finalticketIdSet);
                            if(String.isNotBlank(complaintAndChildQuery)){
                                //Added - W-000378
                                if((System.Limits.getCpuTime() < System.Limits.getLimitCpuTime()) || (System.Limits.getQueries() < 1000)) {
                                    for(sObject sObj : Database.query(complaintAndChildQuery)){
                                        //Added - W-000378
                                        if((System.Limits.getCpuTime() < System.Limits.getLimitCpuTime()) || (System.Limits.getQueries() < 1000)) {
                                            Ticket_Search_Result__c ticketSearchResultRec = processComplaintAndChildsData(sObj);
                                            if(ticketSearchResultRec != new Ticket_Search_Result__c()){
                                                ticketSearchResultsList.add(ticketSearchResultRec);
                                                ticketReviewExistingTicketIdSet.add(ticketSearchResultRec.Ticket__c);
                                            }
                                        }else {
                                            //Added - W-000378
                                            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,Label.General_CPU_Time_Limit));
                                            break;
                                        }
                                    }
                                }else {
                                    //Added - W-000378
                                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,Label.General_CPU_Time_Limit));
                                    break;
                                }
                            }
                        }
                    }
                    if(ticketSearchResultsList.size() > 0 && ticketSearchResultsList.size() < 1001){
                        ticketSearchResultUpdateList.addAll(ticketSearchResultsList);
                        ID jobID = System.enqueueJob(new UpdateSearchResultRecords(ticketSearchResultsList));
                    }
                    searchlog.Ticket_Review__c = ticketReviewId;
                    searchlog.Search_Date_Time__c = DateTime.now();
                    searchlog.Search_Performed_By__c = UserInfo.getName();
                    searchlog.Search_Criteria__c = userReadableSearchCriteria.removeEnd(' OR ');

                    insert searchlog;

                    if(ticketSearchResultsList.size() > 0 && ticketSearchResultsList.size() < 1001){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,Label.Ticket_Search_Successfully));
                    }else if(ticketSearchResultsList.size() > 1001){
                        //Added - W-000378
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,Label.Ticket_Search_Narrow_search));
                    }else if(searchCriteriaList.size() == 0){
                        //Added, W-000402 - If there is no Search record
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,Label.Ticket_Search_No_Search_Criteria));
                    }else{
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,Label.Ticket_Search_Tickets_Not_Found));
                    } //Added, W-000352
                }else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,Label.Ticket_Search_Inactive_Ticket_Review));

                }
            }
        }catch(Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
        }

    }

    /*
    * @Method       : createComplaintAndChildsQuery.
    * @Description  : To construct the query string based on children ticket id set.
    * @Invoke       : From ADDS5DynamicSearchController class.
    * @Return       : String query.
    * @Params       : Set<ID> ticketsIdSet.
    */
    public static String createComplaintAndChildsQuery(Set<ID> ticketsIdSet){
        String query = '';
        if(ticketsIdSet.size() > 0){
            //query = createSelectClause('CMPL123CME__Complaint__c')+',';
            requiredTicketIdSet = new Set<ID>();
            for(ID ticketId : ticketsIdSet){
                if(!ticketReviewExistingTicketIdSet.contains(ticketId)){
                    requiredTicketIdSet.add(ticketId);
                }
            }
            if(requiredTicketIdSet.size() > 0 ){
                if(childObjectAPINameAndQueryMap.size() > 0 && childObjectAPINameAndQueryMap.containsKey('TSB__c')){
                    String tsbQuery = (childObjectAPINameAndQueryMap.get('TSB__c')).replace('TSB__c','TSBs__r');
                    query += '('+ tsbQuery+'),';
                }else{
                    query += '('+ createTSBQuery() +'),';
                }
                if(childObjectAPINameAndQueryMap.size() > 0 && childObjectAPINameAndQueryMap.containsKey('CMPL123CME__MEDDEV__c')){
                    String meddevQuery = (childObjectAPINameAndQueryMap.get('CMPL123CME__MEDDEV__c')).replace('CMPL123CME__MEDDEV__c','CMPL123CME__MEDDEV__r');
                    query += '('+ meddevQuery +'),';
                }else{
                    query += createMeddevQuery() + ',';

                }
                if(childObjectAPINameAndQueryMap.size() > 0 && childObjectAPINameAndQueryMap.containsKey('CMPL123CME__EMDR__c')){
                    String eMDRQuery = (childObjectAPINameAndQueryMap.get('CMPL123CME__EMDR__c')).replace('CMPL123CME__EMDR__c','CMPL123CME__EMDR__r');
                    query += '('+ eMDRQuery +'),';
                } 
                if(childObjectAPINameAndQueryMap.size() > 0 && childObjectAPINameAndQueryMap.containsKey('CMPL123CME__EU_MIR__c')){
                    String eUMIRQuery = (childObjectAPINameAndQueryMap.get('CMPL123CME__EU_MIR__c')).replace('CMPL123CME__EU_MIR__c','CMPL123CME__EU_MIR__r');
                    query += '('+ eUMIRQuery +'),';
                }else{
                    query +=  createEMDRQuery() + ',';
                }
                query = query.removeEnd(',');
                query = createSelectClause('CMPL123CME__Complaint__c','TicketReview',new List<String>())+','+query+ ' FROM CMPL123CME__Complaint__c WHERE ID IN : requiredTicketIdSet';
            }
        }
        return query;
    }

    /*
    * @Method       : createSearchQuery.
    * @Description  : To construct the query string based on the JSON formatted search criteria.
    * @Invoke       : From ADDS5DynamicSearchController class, ADDSearchController class.
    * @Return       : Map<String,Set<String>>.
    * @Params       : String searchCriteriaJSON, String identifier, List<String> ticketFieldsList.
    */
    public static Map<String,Set<String>> createSearchQuery(String searchCriteriaJSON,String identifier,List<String> ticketFieldsList){
        String query;
        Map<String,Set<String>> resultMap = new Map<String,Set<String>>();
        if(String.isNotBlank(searchCriteriaJSON)){
            String fromClause = 'FROM ';
            String WhereClause = 'WHERE ';
            String mainQuery;
            List<String> innerQueryList = new List<String>();
            objectsIncludedInSearchSet = new Set<String>();
            searchingChildObjectsSet = new Set<String>();
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
                //if(String.isNotBlank(searchingObjInner.relationshipName) && searchingObjInner.relationshipName != 'null')
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

                        sequenceNumberAndDataMap.put(searchingData.sequenceNumber,
                                                     searchingData.fieldAPIName + ' ' + searchingData.operatorSign + ' '+containsInOperatorData);
                    }else{
                        // This map stores the key as sequence number and all the remaining data as value
                        // Eg : {1=Quality_Directive_Number__c='TBD' , 2=Receipt_Date__c>2016-12-27T21:54:44.000+0000....}
                        // 1 ----> key, Quality_Directive_Number__c='TBD' ----> value
                        sequenceNumberAndDataMap.put(searchingData.sequenceNumber,
                                                     searchingData.fieldAPIName + ' ' + searchingData.operatorSign + ' ' + value);
                    }
                }
                whereConditions = createWhereClause(searchingObjInner.logic,searchingObjInner.objectAPIName,
                                                    sequenceNumberAndDataMap,identifier);

                // Handling complaint and child objects
                if(objectsIncludedInSearchSet.contains('CMPL123CME__Complaint__c')){
                    if(isInnerObject){
                        String innerQuery = '('+createSelectClause(searchingObjInner.objectAPIName,identifier,ticketFieldsList)+ ' ' +
                            fromClause + objectApiName + WhereClause + whereConditions.trim()+')';
                        innerQueryList.add(innerQuery);
                    }else{
                        mainQuery = fromClause + objectApiName + WhereClause + whereConditions.trim() + ' LIMIT ' + CMPL123__CMPL_App_Config__c.getOrgdefaults().Search_Result_Limit__c;
                        mainQueryObjectAPINameMap.put('mainQuery',objectApiName.trim());
                    }
                }else{
                    // Constructing queries for child objects without complaint
                    //Updated - W-000378 - Added Limit
                    String childQuery = createSelectClause(searchingObjInner.objectAPIName,identifier,ticketFieldsList)+ ' '+ fromClause +
                        objectApiName+ WhereClause + whereConditions.trim() + ' LIMIT ' + CMPL123__CMPL_App_Config__c.getOrgdefaults().Search_Result_Limit__c;
                    childObjectAPINameAndQueryMap.put(searchingObjInner.objectAPIName,childQuery);
                    childQueriesSet.add(childQuery);
                }
                System.debug('VH Debug:'+ childQueriesSet);

            }
            if(objectsIncludedInSearchSet.contains('CMPL123CME__Complaint__c')){
                if(innerQueryList.size() > 0 ){
                    query = createSelectClause(mainQueryObjectAPINameMap.get('mainQuery'),identifier,ticketFieldsList)+',';
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
                               query =  createSelectClause(mainQueryObjectAPINameMap.get('mainQuery'),identifier,ticketFieldsList) +
                                   ',('+ createTSBQuery() + ')' + ','+createMeddevQuery() + ','+createEMDRQuery() +' '+mainQuery;
                           }else{
                               query =  createSelectClause(mainQueryObjectAPINameMap.get('mainQuery'),identifier,ticketFieldsList) + ' '+mainQuery;
                           }
                       }else{
                           query =  createSelectClause(mainQueryObjectAPINameMap.get('mainQuery'),identifier,ticketFieldsList) +' '+ mainQuery;
                       }
                }
            }
        }
        if(identifier.equalsIgnoreCase('TicketReview')){
            resultMap.put('query',new Set<String>{query});
        }else{
            resultMap.put('query',new Set<String>{query});
            resultMap.put('childQueriesSet',childQueriesSet);
            resultMap.put('searchingChildObjectsSet',searchingChildObjectsSet);
        }

        return resultMap;
    }

    /*
    * @Method       : inClausify.
    * @Description  : To construct the proper clauses.
    * @Invoke       : From ADDS5DynamicSearchController class.
    * @Return       : String inClause.
    * @Params       : List<String> dataSet.
    */
    public static String inClausify(List<String> dataSet) {
        String inClause = String.format( '(\'\'{0}\'\')',
                                        new List<String> { String.join( new List<String>(dataSet) , '\',\'') });
        return inClause;
    }

    /*
    * @Method       : createSelectClause.
    * @Description  : To construct the SELECT clauses for the dynamic query.
    * @Invoke       : From ADDS5DynamicSearchController class.
    * @Return       : String selectClause.
    * @Params       : String objectAPIName, String identifier, List<String> ticketFields.
    */
    private static string createSelectClause(String objectAPIName,String identifier,List<String> ticketFields){
        Map<String,List<String>> objectAPIAndFieldAPINamesMap = new Map<String,List<String>>();
        if(identifier.equalsIgnoreCase('TicketReview')){
            objectAPIAndFieldAPINamesMap.put('TSB__c', new List<String>{'Id','Name','TSB_Description__c','TSB_Type__c','Ticket__c'});
            objectAPIAndFieldAPINamesMap.put('CMPL123CME__Complaint__c', new List<String>{'Id',
                'Name','Was_an_Adverse_Event_Identified__c'});
            objectAPIAndFieldAPINamesMap.put('Product_Ticket__c', new List<string>{'Id','Name','Event_Ticket__c'});
            objectAPIAndFieldAPINamesMap.put('CMPL123CME__MEDDEV__c', new List<string>{'Id','Name',
                'CMPL123CME__Type_of_Report__c','CMPL123_WF_Status__c','CMPL123CME__Complaint__c'});
            objectAPIAndFieldAPINamesMap.put('CMPL123CME__EMDR__c', new List<string>{'Id','RecordType.Name',
                'CMPL123CME__CMPL123_WF_Status__c','Classification__c','CMPL123CME__Complaint__c'});
            Set<String> objectsExcludedSet = new Set<String>{'TSB__c','CMPL123CME__Complaint__c','CMPL123CME__MEDDEV__c','CMPL123CME__EMDR__c'};
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
        }else{
            for(String objectAPI : objectsIncludedInSearchSet){
                if(!objectAPI.equalsIgnoreCase('CMPL123CME__Complaint__c')){
                    List<String> fieldsList = new List<String>();
                    fieldsList.add('Id');
                    if(childObjectAPIAndTicketFieldMap.size() > 0 &&
                       childObjectAPIAndTicketFieldMap.containsKey(objectAPI)){
                           fieldsList.add(childObjectAPIAndTicketFieldMap.get(objectAPI));
                       }
                    objectAPIAndFieldAPINamesMap.put(objectAPI,fieldsList);
                }else{
                    objectAPIAndFieldAPINamesMap.put(objectAPI,ticketFields);
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

    /*
    * @Method       : createWhereClause.
    * @Description  : To construct the WHERE clause for the dynamic query.
    * @Invoke       : From ADDS5DynamicSearchController class.
    * @Return       : String whereConditionString.
    * @Params       : String searchLogic, String objectAPIName, Map<String,String> logicSequenceNumberAndDataMap,
    *                 String identifier.
    */
    private static String createWhereClause(
        String searchLogic, String objectAPIName,
        Map<String,String> logicSequenceNumberAndDataMap,String identifier
    ){

        String whereConditionString = '';
        if(identifier.equalsIgnoreCase('TicketReview')){
            if(objectAPIName.equalsIgnoreCase('CMPL123CME__Complaint__c')){
                whereConditionString += 'Id NOT IN : ticketReviewExistingTicketIdSet AND (';
            }
        }
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
        if(objectAPIName.equalsIgnoreCase('CMPL123CME__Complaint__c')){
            if(identifier.equalsIgnoreCase('TicketReview')){
                whereConditionString += ')';
            }
        }
        return whereConditionString;

    }

    /*
    * @Method       : createMeddevQuery.
    * @Description  : To construct the query string for MEDDEV.
    * @Invoke       : From ADDS5DynamicSearchController class.
    * @Return       : String query.
    * @Params       : N/A.
    */
    private static String createMeddevQuery(){
        String query = '(SELECT Id,Name,CMPL123CME__Type_of_Report__c,CMPL123_WF_Status__c FROM CMPL123CME__MEDDEV__r )';
        return query;
    }

    /*
    * @Method       : createEMDRQuery.
    * @Description  : To construct the query string for EMDR.
    * @Invoke       : From ADDS5DynamicSearchController class.
    * @Return       : String query.
    * @Params       : N/A.
    */
    private static String createEMDRQuery(){
        String query = '(SELECT Id,RecordType.Name,CMPL123CME__CMPL123_WF_Status__c,Classification__c '+
            'FROM CMPL123CME__EMDR__r)';
        return query;
    }

    /*
    * @Method       : createTSBQuery.
    * @Description  : To construct the query string for TSB.
    * @Invoke       : From ADDS5DynamicSearchController class.
    * @Return       : String query.
    * @Params       : N/A.
    */
    private static String createTSBQuery(){
        String query = 'SELECT Id,Name,TSB_Type__c,TSB_Description__c,Ticket__c '+
            'FROM TSBs__r ';
        return query;
    }

    /*
    * @Method       : processComplaintAndChildsData.
    * @Description  : To create Ticket Search Result based on the processing of data from Ticket and its child records.
    * @Invoke       : From ADDS5DynamicSearchController class.
    * @Return       : Ticket_Search_Result__c ticketSearchResultData.
    * @Params       : Sobject complaintAndChildData.
    */
    @TestVisible
    private static Ticket_Search_Result__c processComplaintAndChildsData(Sobject complaintAndChildData){
        CMPL123CME__Complaint__c  ticketRecord = (CMPL123CME__Complaint__c)complaintAndChildData;
        Ticket_Search_Result__c ticketSearchResultData = new Ticket_Search_Result__c();
        Boolean processSearchData = false;
        if(searchingChildObjectsSet.size() > 0){
            for(String childObject : searchingChildObjectsSet){
                if(ticketRecord.getSObjects(childObject) != null && ticketRecord.getSObjects(childObject).size() > 0){
                    processSearchData = true;
                }else{
                    processSearchData = false;
                    break;
                }
            }
            if(processSearchData){
                ticketSearchResultData = createTicketSearchResult(ticketRecord);
            }
        }else{
            ticketSearchResultData = createTicketSearchResult(ticketRecord);
        }
        return ticketSearchResultData;
    }

    /*
    * @Method       : createTicketSearchResult.
    * @Description  : To create Ticket Search Result based on the processing of data from Ticket.
    * @Invoke       : From ADDS5DynamicSearchController class.
    * @Return       : Ticket_Search_Result__c ticketSearchResult.
    * @Params       : CMPL123CME__Complaint__c ticketData.
    */
    @TestVisible
    private static Ticket_Search_Result__c createTicketSearchResult(CMPL123CME__Complaint__c ticketData){
        Ticket_Search_Result__c ticketSearchResult = new Ticket_Search_Result__c();
        ticketSearchResult.Ticket__c = (String)ticketData.get('Id');
        ticketSearchResult.Is_Ticket_Adverse_Event__c = (String)ticketData.get('Was_an_Adverse_Event_Identified__c');
        ticketSearchResult.Ticket_Review__c = ticketReviewId;
        ticketSearchResult.Submission_Information__c = '';
        ticketIdSet.add(ticketSearchResult.Ticket__c);
        for(TSB__c tsb : ticketData.TSBs__r){
            if(tsb.TSB_Type__c != null && tsb.TSB_Type__c.equalsIgnoreCase('Mandatory')){
                ticketSearchResult.FA_Mandatory_TSB_number__c = tsb.Name + (tsb.TSB_Description__c != null ?
                                                                            '~'+tsb.TSB_Description__c : '');
            }
        }
        ticketSearchResult.Total_Number_of_MDI__c = ticketData.CMPL123CME__MEDDEV__r.size();
        ticketSearchResult.Total_Number_of_eMDR__c = ticketData.CMPL123CME__EMDR__r.size();
          //@Juneid 22 June 2021, Added MIR for Search
        ticketSearchResult.Total_Number_of_EU_MIR__c =ticketData.CMPL123CME__EU_MIR__r.size();

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
        //@Juneid 22 June 2021, Added for EUMIR Tciket Search
        for(CMPL123CME__EU_MIR__c euMirRecord : ticketData.CMPL123CME__EU_MIR__r){
            ticketSearchResult.Submission_Information__c +=
                (CMPL123CME__EU_MIR__c.CMPL123CME__Type_of_Report__c != null ? CMPL123CME__EU_MIR__c.CMPL123CME__Type_of_Report__c+'~' : '') +
                +'EUMIR'+
                '~'+CMPL123CME__EU_MIR__c.CMPL123_WF_Status__c+'\n';

        }
        return ticketSearchResult;
    }


    /* this method is added to avoid the Apex CPU time limit error which is caused when you perform search on Ticket review */

    /**
    ##############################################################################
    #  Class Name    : searchingObjectInnerController
    #  Created Date  :
    #  Description   : This class is used to store the searching object related information.
    #############################################################################
    */
    public class searchingObjectInnerController{
        public String objectAPIName;
        public String logic;
        public String objectLabel;
        public String relationshipName;
        public String relatedTicketFieldAPI;
        public List<searchingDataInnerController> searchingDataInnerControllerList;
    }

    /**
    ##############################################################################
    #  Class Name    : searchingObjectInnerController
    #  Created Date  :
    #  Description   : This class is used to store the searching fields related
    information
    #############################################################################
    */

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