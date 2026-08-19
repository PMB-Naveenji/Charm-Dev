/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : InvestigationTaskTriggerHandler.
* @Why   : Public class to manage all the custom coding invoked on the Task__c object.
* @When  : 23-MAR-2017.
* @Where : From ADDInvestigationTaskTriggerHandler.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit           Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit           Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    18-AUG-2020            Code Audit           Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
* Yadram                   10-MAR-2022            CHaRM R2.1           Fixed Defect 131(Added fields in the ticket search object)
* --------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar(COE)        01-JUN-2023            CHARM R3.1           A new method "preventDeletionifTaskStatusNotOpenedOrNotInprocess" 
                                                                       is created to Restrict the delete operation by throwing a error 
                                                                       when a Evaluation/Investigation Task record has workflow status 
                                                                       is not "Opened" or In-Process" and the user deleting the record is 
                                                                       not a owner or Assignee.
                                                                       Also updated method "beforeDeleteEventHandler" to call method 
                                                                       "preventDeletionifTaskStatusNotOpenedOrNotInprocess"
* --------------------------------------------------------------------------------------------------------------------------------------
* Charm COE               07-Jul-2025.           IPDR-575            Updated method "afterEventHandler" to support both sublot-based and 
																	   regular lot-based matching for Product_Ticket__c. Dynamically builds 
																	   and executes appropriate SOQL queries and maps tickets back to related 
																	   Task__c records.
* ----------------------------------------------------------------------------------------------------------------------------------------------
* Charm COE               08-Jan-2026           IPDR-792, IPDR-793   Updated method "afterEventHandler", to improve query performance and fix 
												IPDR-794			 timeout error. Implemented SOSL to find  Product_Ticket__c IDs If record range 
																	 equal to 2000 else switch to dynamic SOQL .
* ----------------------------------------------------------------------------------------------------------------------------------------------
*/
public class InvestigationTaskTriggerHandler {

    static Map < String, String > recordTypeNameWithIdMap;
    public static Boolean executingThroughInvokable = false;

    /*
    * @Method       : beforeEventHandler.
    * @Description  : Hanlde events for before insert and before update.
    * @Invoke       : From ADDInvestigationTaskTriggerHandler.beforeInsert method.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void beforeEventHandler() {
        List < Task__c > newTasksList = (List < Task__c > ) Trigger.New;
        for (Task__c newTask: newTasksList) {
            if (newTask.Requestor_Name__c == null) {
                newTask.Requestor_Name__c = userinfo.getUserId();
            }
            if (newTask.Parent_Ticket__c == null && newTask.Related_Investigation_Evaluation__c != null &&
                newTask.Related_Investigation_Evaluation__r.CMPL123CME__Complaint__c != null) {
                    newTask.Parent_Ticket__c = newTask.Related_Investigation_Evaluation__r.CMPL123CME__Complaint__c;
                }
        }
    }

    /*
    * @Method       : afterEventHandler.
    * @Description  : Hanlde events for after update.
    * @Invoke       : From ADDInvestigationTaskTriggerHandler.afterUpdate method.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void afterEventHandler() {

        List < Task__c > newTasks = (List < Task__c > ) Trigger.New;
        Map < Id, Task__c > oldTaskMap = (Map < Id, Task__c > ) Trigger.oldMap;
        Map < Id, Task__c > newTaskMap = (Map < Id, Task__c > ) Trigger.newMap;
        if (recordTypeNameWithIdMap == null) {
            recordTypeNameWithIdMap = new Map < String, String > ();
            for (RecordType rt: [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType Where SobjectType = 'Task__c']) {
                recordTypeNameWithIdMap.put(rt.Name, rt.Id);
                recordTypeNameWithIdMap.put(rt.Id, rt.Name);
            }
        }

        Map < String, Task__c > batchLotWithTaskMap = new Map < String, Task__c > ();
        Map < String, Task__c > productListWithTaskMap = new Map < String, Task__c > ();
        // Added - W-000109 - Start
        Map < String, Task__c > productListBaseWithTaskMap = new Map < String, Task__c > ();
        Map < String, Task__c > trendingIssueBucketWithTaskMap = new Map < String, Task__c > ();
        // Added - W-000109 - End
        Set < String > productEvaluationIds = new Set < String > ();

        for (Task__c task: [SELECT Id, Name, Parent_Ticket__c, Parent_Ticket__r.Trending_issue_Bucket__c,Likely_Cause_Only__c ,
                            Product_Ticket__r.Product__r.List_Base__c,CMPL123_WF_Status__c,Timeframe_in_Months__c,
                            Related_Investigation_Evaluation__c,Include_Complaints__c,Include_Demand_Service_Tickets__c,
                            Lot_to_Review__c,Serial_Number_to_Review1__c,RecordTypeId,Include_Sublot__c FROM Task__c WHERE Id IN: newTasks]) {
                                Task__c oldTask = Trigger.isUpdate ? oldTaskMap.get(task.Id) : null;

                                if (Trigger.isUpdate && newTaskMap.get(task.Id).CMPL123_WF_Status__c == 'Closed-Done' && newTaskMap.get(task.Id).CMPL123_WF_Status__c != oldTask.CMPL123_WF_Status__c && newTaskMap.get(task.Id).Related_Investigation_Evaluation__c != null)
                                    productEvaluationIds.add(newTaskMap.get(task.Id).Related_Investigation_Evaluation__c);

                                if ((recordTypeNameWithIdMap.get(newTaskMap.get(task.Id).RecordTypeId) == 'Ticket History Review By Lot Number' ||
                                     recordTypeNameWithIdMap.get(newTaskMap.get(task.Id).RecordTypeId) == 'Ticket History Review By Product List Number' ||
                                     recordTypeNameWithIdMap.get(newTaskMap.get(task.Id).RecordTypeId) == 'Instrument Service History Review') &&
                                     (newTaskMap.get(task.Id).CMPL123_WF_Status__c == 'In Process' && newTaskMap.get(task.Id).CMPL123_WF_Action__c == 'Submit')  //
                                    && (oldTask == null || (oldTask != null && newTaskMap.get(task.Id).CMPL123_WF_Status__c != oldTask.CMPL123_WF_Status__c))
                                    && (newTaskMap.get(task.Id).Include_Complaints__c ||
                                        newTaskMap.get(task.Id).Include_Demand_Service_Tickets__c)) {
                                            if (recordTypeNameWithIdMap.get(newTaskMap.get(task.Id).RecordTypeId) == 'Ticket History Review By Lot Number' && (newTaskMap.get(task.Id).Lot_to_Review__c != '' || newTaskMap.get(task.Id).Lot_to_Review__c != null)) {
                                                batchLotWithTaskMap.put(newTaskMap.get(task.Id).Lot_to_Review__c.toUpperCase(), task);
                                            } else if (recordTypeNameWithIdMap.get(newTaskMap.get(task.Id).RecordTypeId) == 'Ticket History Review By Product List Number') {
                                                // Added - W-000109 - Start
                                                if(task.Product_Ticket__r.Product__r.List_Base__c != null && task.Product_Ticket__r.Product__r.List_Base__c != '')
                                                    productListBaseWithTaskMap.put(task.Product_Ticket__r.Product__r.List_Base__c, task);
                                                system.debug('productListBaseWithTaskMap'+productListBaseWithTaskMap);
                                                if(task.Parent_Ticket__r.Trending_issue_Bucket__c != null && task.Parent_Ticket__r.Trending_issue_Bucket__c != '')
                                                    trendingIssueBucketWithTaskMap.put(task.Parent_Ticket__r.Trending_issue_Bucket__c, task);
                                                system.debug('trendingIssueBucketWithTaskMap'+trendingIssueBucketWithTaskMap);
                                                // Added - W-000109 - End
                                            } else {
                                                batchLotWithTaskMap.put(newTaskMap.get(task.Id).Serial_Number_to_Review1__c, task);
                                            }
                                        }
                            }

        if (productEvaluationIds.size() > 0) {
            List < CMPL123CME__Investigation__c > updatableInvestigations = new List < CMPL123CME__Investigation__c > ();
            for (CMPL123CME__Investigation__c investigation
                 : [SELECT Id, CMPL123Task_Key_Value__c, CMPL123Rule_Key_Value__c,
                    (SELECT Id FROM Related_Evaluation_Investigation_Tasks__r WHERE CMPL123_WF_Status__c != 'Closed-Done') FROM
                    CMPL123CME__Investigation__c WHERE Id IN: productEvaluationIds AND CMPL123_WF_Status__c = 'In Process-Investigation'
                   ]) {
                       if (investigation.Related_Evaluation_Investigation_Tasks__r.size() == 0) {
                           updatableInvestigations.add(new CMPL123CME__Investigation__c(
                               Id = investigation.Id,
                               CMPL123Task_Key_Value__c = investigation.CMPL123Rule_Key_Value__c == 'PRODEVAL_WORKFLOW' ? 'CompleteADDProdEval' : 'CompleteAMDProdEval'
                           ));
                       }
                   }
            if (updatableInvestigations.size() > 0) {

                update updatableInvestigations;
            }
        }

        if (!executingThroughInvokable) {
            Set < String > complaintIds = new Set < String > ();
            //10-MAR-2022 Yadram : Need to create Map for Fetch Ticket Id with Ticket Search records to fix the Defect no 325.
            Map<String, List<Ticket_Serach__c>> prodLotNumToTicketSearchRecList =
                new Map<String, List<Ticket_Serach__c>>();
            
            //IPDR-575
            List<Product_Ticket__c> productTicketList = new List<Product_Ticket__c>();
            Set<String> regularLotKeys = new Set<String>();
            List<String> sublotPrefixes = new List<String>();
            Boolean useSublotMatching = false;
            //Divide lot keys into sublot and regular lots based on Include_Sublot__c
            for (String lot : batchLotWithTaskMap.keySet()) {
                Task__c task = batchLotWithTaskMap.get(lot);
                if (task != null && task.Include_Sublot__c == true && lot != null && lot.length() == 9) {
                    // If sublot is enabled, extract the prefix (excluding last 2 chars) and store
                    String prefix = lot.substring(0, lot.length() - 2);
                    sublotPrefixes.add(prefix);
                    useSublotMatching = true;
                } else {
                    // Otherwise, treat as regular lot
                    regularLotKeys.add(lot);
                }
            }
            // Get all Product-Tickets
            if (useSublotMatching) {
                // IPDR-793: Run SOSL to fetch Product_Ticket__c Ids where Batch_Lot_Serial__c matches the prefix.
                String lot = sublotPrefixes[0] + '*';
                Integer soslLimit = Integer.valueOf(System.Label.SOSL_LIMIT);//SOSL_LIMIT is set 2000 in custom label.
                List<List<SObject>> soslResults = [
                    FIND :lot IN ALL FIELDS
                    RETURNING Product_Ticket__c (
                        Id WHERE Likely_Cause__c = 'Yes' AND Batch_Lot_Serial__c LIKE :(sublotPrefixes[0] + '%') 
                        AND (Event_Ticket__r.Ticket_Type__c = 'Complaint' OR Event_Ticket__r.Ticket_Type__c = 'Service')
                        LIMIT : soslLimit
                    )];
                Set<Id> productTicketIds = new Set<Id>();
                for (SObject sobj : soslResults.isEmpty() ? new List<SObject>() : soslResults[0]) {
                    productTicketIds.add(sobj.Id);
                }
                if(productTicketIds.size() == Integer.valueOf(System.Label.SOSL_LIMIT)){
                    //IPDR-793: If any task uses sublot logic and SOSL returns 2000 records, use dynamic SOQL with LIKE conditions
                    List<String> likeConditions = new List<String>();
                    for (String prefix : sublotPrefixes) {
                        likeConditions.add('Batch_Lot_Serial__c LIKE \'' + String.escapeSingleQuotes(prefix) + '%\'');
                    }
                    
                    String finalQuery = 'SELECT Id, Event_Ticket__r.Serial__c ,Event_Ticket__r.Ticket_Type__c, Event_Ticket__r.Investigation_Conclusion__c, ' +
                        'Batch_Lot_Serial__c, Likely_Cause__c, Product_List_Number__c, ' +
                        'Event_Ticket__r.Registration_Ticket__c, Event_Ticket__r.Trending_issue_Bucket__c, Product__r.List_Base__c, ' +
                        'Event_Ticket__r.Ticket_Close_Date__c, Event_Ticket__r.CMSNext_Ticket_Number__c, ' +
                        'Event_Ticket__c, Event_Ticket__r.Receipt_Date__c, Product__c, Product__r.Likely_Cause__c, ' +
                        'Event_Ticket__r.Service_Type__c, Event_Ticket__r.Customer_Reply_Required__c, Event_Ticket__r.Country_of_origin__c, ' +
                        'Event_Ticket__r.Issue_Code_Description_Concat__c ' +
                        'FROM Product_Ticket__c ' +
                        'WHERE Likely_Cause__c = \'Yes\' ' +
                        'AND ' + String.join(likeConditions, ' OR ') +
                        'AND (Event_Ticket__r.Ticket_Type__c = \'Complaint\' OR Event_Ticket__r.Ticket_Type__c = \'Service\')';
                    
                    /*String finalQuery = 'SELECT Id, Event_Ticket__r.Serial__c ,Event_Ticket__r.Ticket_Type__c, Event_Ticket__r.Investigation_Conclusion__c, ' +
                    'Batch_Lot_Serial__c, Likely_Cause__c, Product_List_Number__c, ' +
                    'Event_Ticket__r.Registration_Ticket__c, Event_Ticket__r.Trending_issue_Bucket__c, Product__r.List_Base__c, ' +
                    'Event_Ticket__r.Ticket_Close_Date__c, Event_Ticket__r.CMSNext_Ticket_Number__c, ' +
                    'Event_Ticket__c, Event_Ticket__r.Receipt_Date__c, Product__c, Product__r.Likely_Cause__c, ' +
                    'Event_Ticket__r.Service_Type__c, Event_Ticket__r.Customer_Reply_Required__c, Event_Ticket__r.Country_of_origin__c, ' +
                    'Event_Ticket__r.Issue_Code_Description_Concat__c ' +
                    'FROM Product_Ticket__c ' +
                    'WHERE Likely_Cause__c = \'Yes\' ' +
                    'AND (' + String.join(likeConditions, ' OR ') + 
                    ' OR (Product__r.List_Base__c IN (' + listBaseInClause + ') ' +
                    'AND Event_Ticket__r.Trending_issue_Bucket__c IN (' + trendingBucketInClause + '))) ' +
                    'AND (Event_Ticket__r.Ticket_Type__c = \'Complaint\' OR Event_Ticket__r.Ticket_Type__c = \'Service\')';*/
                    productTicketList = Database.query(finalQuery);
                }else{
                    // If any task uses sublot logic and SOSL returns less than 2000 records, use SOQL with exact filer of Product Ticket record Ids.
                    if (!productTicketIds.isEmpty()) {
                        productTicketList = [SELECT Id, Event_Ticket__r.Serial__c ,Event_Ticket__r.Ticket_Type__c,
                                             Event_Ticket__r.Investigation_Conclusion__c, Batch_Lot_Serial__c, Likely_Cause__c, Product_List_Number__c,
                                             Event_Ticket__r.Registration_Ticket__c, Event_Ticket__r.Trending_issue_Bucket__c, Product__r.List_Base__c,
                                             Event_Ticket__r.Ticket_Close_Date__c, Event_Ticket__r.CMSNext_Ticket_Number__c, Event_Ticket__c,
                                             Event_Ticket__r.Receipt_Date__c, Product__c, Product__r.Likely_Cause__c,
                                             Event_Ticket__r.Service_Type__c, Event_Ticket__r.Customer_Reply_Required__c,
                                             Event_Ticket__r.Country_of_origin__c, Event_Ticket__r.Issue_Code_Description_Concat__c
                                             FROM Product_Ticket__c WHERE Id IN :productTicketIds AND Likely_Cause__c = 'Yes'
                                             AND (Event_Ticket__r.Ticket_Type__c = 'Complaint' OR Event_Ticket__r.Ticket_Type__c = 'Service')];
                    }
                }
            } else {
                // If sublot matching is not used, fallback to simple IN clause query
                productTicketList = [
                    SELECT Id, Event_Ticket__r.Serial__c ,Event_Ticket__r.Ticket_Type__c,
                    Event_Ticket__r.Investigation_Conclusion__c, Batch_Lot_Serial__c, Likely_Cause__c, Product_List_Number__c,
                    Event_Ticket__r.Registration_Ticket__c, Event_Ticket__r.Trending_issue_Bucket__c, Product__r.List_Base__c,
                    Event_Ticket__r.Ticket_Close_Date__c, Event_Ticket__r.CMSNext_Ticket_Number__c, Event_Ticket__c,
                    Event_Ticket__r.Receipt_Date__c, Product__c, Product__r.Likely_Cause__c,
                    Event_Ticket__r.Service_Type__c, Event_Ticket__r.Customer_Reply_Required__c,
                    Event_Ticket__r.Country_of_origin__c, Event_Ticket__r.Issue_Code_Description_Concat__c
                    FROM Product_Ticket__c
                    WHERE Likely_Cause__c = 'Yes'
                    AND (Batch_Lot_Serial__c IN :regularLotKeys OR 
                         (Product__r.List_Base__c IN :productListBaseWithTaskMap.keySet() 
                          AND Event_Ticket__r.Trending_issue_Bucket__c IN :trendingIssueBucketWithTaskMap.keySet()))
                    AND (Event_Ticket__r.Ticket_Type__c = 'Complaint' OR Event_Ticket__r.Ticket_Type__c = 'Service')
                ];
            }
            // Map Batch_Lot_Serial__c to Task__c based on whether sublot or regular
            Map<String, Task__c> lotSerialToTaskMap = new Map<String, Task__c>();
            if (useSublotMatching) {
                // Handle sublot match
                if (!batchLotWithTaskMap.isEmpty()) {
                    for (String lot : batchLotWithTaskMap.keySet()) {
                        Task__c task = batchLotWithTaskMap.get(lot);
                        if (task.Include_Sublot__c && lot != null && lot.length() == 9) {
                            String prefix = lot.substring(0, lot.length() - 2); 
                            for (Product_Ticket__c pt : productTicketList) {
                                //IPDR-575 - Converting the lot number to uppercase to handle case senstivity for Batch Lot Serial in Product Tickets.
                                if (pt.Batch_Lot_Serial__c != null && pt.Batch_Lot_Serial__c.toUpperCase().startsWith(prefix)) {
                                    lotSerialToTaskMap.put(pt.Batch_Lot_Serial__c.toUpperCase(), task);
                                }
                            }
                        }
                    }
                }
            } else {
                // Regular mapping from lot directly to task
                for (String lot : batchLotWithTaskMap.keySet()) {
                    lotSerialToTaskMap.put(lot, batchLotWithTaskMap.get(lot));
                }
            }
            //IPDR-575
            // Collect the Product-Ticket Ids
            List<Id> productTicketIdList = new List<Id>();
            for (Product_Ticket__c productTicket : productTicketList) {
                productTicketIdList.add(productTicket.Id);
            }

            // For each Ticket, keep track of the Conclusion Disposition
            Map<Id, String> productTicketIdToConcDispo = new Map<Id, String>();
            for (Product_Lot__c prodLot : [
                SELECT Id, Product_Lot_Number__c,Product_Name__c,
                Product_Evaluation_Investigation__r.CMPL123CME__Complaint__c,
                Product_Evaluation_Investigation__r.Conclusion_Disposition__c
                FROM Product_Lot__c
                WHERE Product_Name__c IN :productTicketIdList
            ]) {
                Id productTicketId = prodLot.Product_Name__c;
                productTicketIdToConcDispo.put(productTicketId,
                    prodLot.Product_Evaluation_Investigation__r.Conclusion_Disposition__c);
            }

            // Added - W-000088
            for (Product_Ticket__c productTicket : productTicketList) {
                if (String.isBlank(productTicket.Event_Ticket__c)) {
                    continue;
                }
				// IPDR-575 - Ticket searches are generated for unique combination of Ticket & Batch lot serial number of product ticket for Task of type Ticket History Review By Lot Number.
				// IPDR-792: ComboKey is used to: Identify duplicate Ticket search requests and Prevent duplicate entries in the complaintIds set
				String comboKey;
                if((productTicket.Batch_Lot_Serial__c != null || productTicket.Batch_Lot_Serial__c != '' ) && 
                   lotSerialToTaskMap.size() > 0 && lotSerialToTaskMap.get(productTicket.Batch_Lot_Serial__c.toUpperCase()) !=null &&
                   recordTypeNameWithIdMap.get(lotSerialToTaskMap.get(productTicket.Batch_Lot_Serial__c.toUpperCase()).RecordTypeId) == 'Ticket History Review By Lot Number'){
                       //IPDR-792: Tasks with Record Type = "Ticket History Review By Lot Number, When the "Include Sub‑Lot" option is checked,  
                       //searches must be generated per unique combination of Event Ticket Id + Batch/Lot Serial Number.
                       comboKey = productTicket.Event_Ticket__c + '|' + productTicket.Batch_Lot_Serial__c.toUpperCase();
                   }else{
                       //IPDR-792: All other record types, including:"Ticket History Review By Lot Number" when Include Sub‑Lot is NOT checked 
                       //Any other Task Record Type, searches are generated only at the Event Ticket level.
                       comboKey = productTicket.Event_Ticket__c;
                   }
                if (!complaintIds.contains(comboKey)) {
                    Task__c eligibleTask;
                    if ((productTicket.Batch_Lot_Serial__c != null || productTicket.Batch_Lot_Serial__c != '' ) && 
                        //IPDR-793:Handle the bug using "lotSerialToTaskMap.get(productTicket.Batch_Lot_Serial__c.toUpperCase()) !=null" check.
                        lotSerialToTaskMap.size() > 0 && lotSerialToTaskMap.get(productTicket.Batch_Lot_Serial__c.toUpperCase()) !=null  && 
                        lotSerialToTaskMap.get(productTicket.Batch_Lot_Serial__c.toUpperCase()).RecordTypeId != null &&
                        recordTypeNameWithIdMap.get(lotSerialToTaskMap.get(productTicket.Batch_Lot_Serial__c.toUpperCase()).RecordTypeId) == 'Ticket History Review By Lot Number'
                       ) {
                           //eligibleTask = batchLotWithTaskMap.get(productTicket.Batch_Lot_Serial__c);
                           eligibleTask = lotSerialToTaskMap.get(productTicket.Batch_Lot_Serial__c.toUpperCase());
                           //Updated - W-000109 - Start
                       }else if(lotSerialToTaskMap.size() > 0 && lotSerialToTaskMap.get(productTicket.Batch_Lot_Serial__c) != null &&
                                lotSerialToTaskMap.get(productTicket.Batch_Lot_Serial__c).RecordTypeId != null &&
                                recordTypeNameWithIdMap.get(lotSerialToTaskMap.get(productTicket.Batch_Lot_Serial__c).RecordTypeId) == 'Instrument Service History Review'
                               ) {
                                   //eligibleTask = batchLotWithTaskMap.get(productTicket.Batch_Lot_Serial__c);
                                   eligibleTask = lotSerialToTaskMap.get(productTicket.Batch_Lot_Serial__c);
                       }else if (productListBaseWithTaskMap.get(productTicket.Product__r.List_Base__c) != null &&
                                  productListBaseWithTaskMap.get(productTicket.Product__r.List_Base__c).RecordTypeId != null &&
                                  recordTypeNameWithIdMap.get(productListBaseWithTaskMap.get(productTicket.Product__r.List_Base__c).RecordTypeId) == 'Ticket History Review By Product List Number'
                                 ) {
                                     eligibleTask = productListBaseWithTaskMap.get(productTicket.Product__r.List_Base__c);
                                 }//Updated - W-000109 - End
                    
                    if (eligibleTask != null && (
                        (eligibleTask.Include_Complaints__c && productTicket.Event_Ticket__r.Ticket_Type__c == 'Complaint') ||
                        (eligibleTask.Include_Demand_Service_Tickets__c && productTicket.Event_Ticket__r.Ticket_Type__c == 'Service' && productTicket.Event_Ticket__r.Service_Type__c == 'Demand'))
                       ) {
                           Date timeFrame;
                           if (eligibleTask.Timeframe_in_Months__c != null)
                               timeFrame = Date.Today().addMonths(-Integer.valueOf(eligibleTask.Timeframe_in_Months__c));
                           
                           if ((timeFrame == null || (timeFrame != null && productTicket.Event_Ticket__r.Receipt_Date__c > timeFrame)) &&
                               productTicket.Event_Ticket__r.Receipt_Date__c < Date.Today() &&
                               (!eligibleTask.Likely_Cause_Only__c ||
                                (eligibleTask.Likely_Cause_Only__c && productTicket.Likely_Cause__c == 'Yes'))
                              ) {
                                  //Added - W-000088
                                  //10-MAR-2022 Yadram : Added fields on the Ticket Search for fix the Defect 131
                                  List<Ticket_Serach__c> ticketSearches = prodLotNumToTicketSearchRecList.get(eligibleTask.Lot_to_Review__c);
                                  if (ticketSearches == null) {
                                      ticketSearches = new List<Ticket_Serach__c>();
                                  }
                                  String concDispo = productTicketIdToConcDispo.get(productTicket.Id);
                                  ticketSearches.add(new Ticket_Serach__c( 
                                      Evaluation_Investigation_Task__c = eligibleTask.Id,
                                      Receipt_Date__c = productTicket.Event_Ticket__r.Receipt_Date__c,
                                      Ticket_Close_Date__c = productTicket.Event_Ticket__r.Ticket_Close_Date__c,
                                      Ticket_Investigation_Conclusion__c = productTicket.Event_Ticket__r.Investigation_Conclusion__c,
                                      Registration_Tkt_Number__c = productTicket.Event_Ticket__r.CMSNext_Ticket_Number__c,
                                      Registration_Ticket_Number__c = productTicket.Event_Ticket__c + '-' + productTicket.Event_Ticket__r.Registration_Ticket__c,
                                      Trending_Issue_Bucket__c = productTicket.Event_Ticket__r.Trending_issue_Bucket__c,
                                      Product_List_Part_Number__c = productTicket.Product_List_Number__c,
                                      Batch_Lot_Serial__c = productTicket.Batch_Lot_Serial__c,
                                      Country_of_Origin__c = productTicket.Event_Ticket__r.Country_of_Origin__c,
                                      Customer_Reply_Required__c = productTicket.Event_Ticket__r.Customer_Reply_Required__c,
                                      Issue_Code_Description__c = productTicket.Event_Ticket__r.Issue_Code_Description_Concat__c,
                                      Conclusion_Disposition__c = concDispo)
                                                    );
                                  prodLotNumToTicketSearchRecList.put(eligibleTask.Lot_to_Review__c, ticketSearches);
                                  complaintIds.add(comboKey);
                              }
                       } 
                }
            }
            
            executingThroughInvokable = true;
            //10-MAR-2022 Yadram : Replace list to Map values for Fix the Defect 131.
            List<Ticket_Serach__c> toInsert = new List<Ticket_Serach__c>();
            for (String productLotNum : prodLotNumToTicketSearchRecList.keySet()) {
                List<Ticket_Serach__c> ticketSearchList =
                    prodLotNumToTicketSearchRecList.get(productLotNum);
                if (ticketSearchList == null) {
                    ticketSearchList = new List<Ticket_Serach__c>();
                }
                toInsert.addAll(ticketSearchList);
            }
            if (!toInsert.isEmpty()) {
                insert toInsert;
            }
        }
    }
    /*
    * @Method       : createTaskJunction.
    * @Description  : To create junction(Task_Product_Evaluation_Investigation__c) record.
    * @Invoke       : From ADDInvestigationTaskTriggerHandler.afterInsert method.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void createTaskJunction() {
        List < Task__c > newTasks = (List < Task__c > ) Trigger.New;
        List < Task_Product_Evaluation_Investigation__c > newJunctionRecords = new List < Task_Product_Evaluation_Investigation__c > ();
        for (Task__c task: newTasks) {
            if (task.Related_Investigation_Evaluation__c != null) {
                newJunctionRecords.add(
                    new Task_Product_Evaluation_Investigation__c(
                        Investigation_Evaluation__c = task.Related_Investigation_Evaluation__c,
                        Source_Leveraged__c = 'Source',
                        Task__c = task.Id
                    )
                );
            }
        }
        if (newJunctionRecords.size() > 0) {
            insert newJunctionRecords;
        }
    }

    /*
    * @Method       : beforeDeleteEventHandler.
    * @Description  : Handles before delete.
    * @Invoke       : From ADDInvestigationTaskTriggerHandler.beforeDelete method.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void beforeDeleteEventHandler() {
        Set < String > taskSet = new Set < String > ();
        List < Task__c > oldTaskList = (List < Task__c > ) Trigger.Old;
        //Added W-000365
        preventDeletionifParentClosedPEReview((Map<Id, Task__c>)Trigger.OldMap);
         //Added W-000365
         //IPDR 82 start - CHARM 3.1 By Dinesh Kumar(COE)
        preventDeletionifTaskStatusNotOpenedOrNotInprocess((Map<Id,Task__c>)Trigger.oldMap);
         //IPDR 82 end - CHARM 3.1 By Dinesh Kumar(COE)
        for (Task_Product_Evaluation_Investigation__c relatedJunctionTasks
             : [SELECT Id, Name,
                Investigation_Evaluation__c, Task__c, Source_Leveraged__c FROM Task_Product_Evaluation_Investigation__c
                WHERE Task__c IN: oldTaskList AND Source_Leveraged__c = 'Leveraged'
               ]) {
                   taskSet.add(relatedJunctionTasks.Task__c);
               }
        for (Task__c task: oldTaskList) {
            if (taskSet.contains(task.Id)) {
                task.addError(System.Label.Task_Product_Evaluation_Investigation_Task_Deleted);
            }
        }
    }

    /*
    * @Method       : preventDeletionifParentClosedPEReview.
    * @Description  : Added W-000365: prevent pro eval task deletion if parent closed/PE Review.
    * @Invoke       : From ADDInvestigationTaskTriggerHandler.beforeDelete method.
    * @Return       : N/A.
    * @Params       : Map<Id, Task__c> mapOldTasks.
    */
    private static void preventDeletionifParentClosedPEReview(Map<Id, Task__c> mapOldTasks) {
        for(Task__c objTask : [SELECT Id,Related_Investigation_Evaluation__c,
                                Related_Investigation_Evaluation__r.CMPL123_WF_Status__c
                                FROM Task__c WHERE Id =: mapOldTasks.keySet()]){
            if(objTask.Related_Investigation_Evaluation__c != null
                    && (objTask.Related_Investigation_Evaluation__r.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done
                    || objTask.Related_Investigation_Evaluation__r.CMPL123_WF_Status__c == AspenConstants.STR_PE_Review)
                )
                mapOldTasks.get(objTask.Id).addError(System.label.PreventDeleteTaskwhenProdEvalClosedPEReview);
        }
    }
    
   /*
    * @Method       : preventDeletionifTaskStatusNotOpenedOrNotInprocess.
    * @Description  : Restrict deletions when a Evaluation/Investigation Task record has workflow status not in "Opened" or "In-Process" or the user is not a owner or Assignee
    * @Invoke       : From ADDInvestigationTaskTriggerHandler.beforeDelete method.
    * @Params       : Map<Id, Task__c> mapOldTasks.
    * @Release      : CHARM 3.1- IPDR 82
    */
   //IPDR 82 start - CHARM 3.1 By Dinesh Kumar(COE)
    private static void preventDeletionifTaskStatusNotOpenedOrNotInprocess(Map<Id, Task__c> mapOldTasks) {
        Set<String> checkStatus= new Set<String>{AspenConstants.STR_WF_Opened, AspenConstants.STR_In_Process};
        for(Task__c task : mapOldTasks.values()){
            Set<String> checkUser = new Set<String>{task.Assignee_Name__c, task.ownerId};
            if( !checkUser.contains(UserInfo.getUserId()) || !checkStatus.contains(task.CMPL123_WF_Status__c )){
                task.addError(System.Label.Cannot_delete_evaluation_Investigation_Task_if_not_in_Opened_or_Inprocess_status);
            }
        }
    }
    //IPDR 82 End - CHARM 3.1 By Dinesh Kumar(COE)
}