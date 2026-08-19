/**
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : ADDMDCTicketTriggerHandler
* @Why   : Handles all the customization involved on custom MDC Ticket object
* @When  : 12-SEP-2018
* @Where : From Action_Task_AuditTrigger Trigger
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    12-SEP-2018            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit           Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit           Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    28-DEC-2020            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    28-DEC-2020            TWD Upgrade issue    Added 'executeLogicFromWFRules()' method to move logic from
*                                                                      Workflow Rules with Field Updates on MDC Ticket to Apex.
*                                                                      Added 'beforeInsert()', 'beforeUpdate()' methods.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    20-JAN-2021            Defect #33           Added additional logic to populate ticket data on MDC record when
*                                                                      when related record is not directly linked to ticket.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    09-FEB-2021            Defect #151          Added new inner class to move certain logic from @future to
*                                                                      Queueable
* --------------------------------------------------------------------------------------------------------------------------------------
* Neeraj Soni              13-MAR-2021            Defect #179           Added ticketToConfigure.put('MDC_Last_Updated_Date__c', System.today());for Defect #179
* --------------------------------------------------------------------------------------------------------------------------------------
* Aslam Juneid             05-August-2021         Code Audit           Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* Aslam Juneid             16-Sep-2021             MIR MDC              Added a Lgiv for MIR Regulatory Task
* --------------------------------------------------------------------------------------------------------------------------------------
**/
public class ADDMDCTicketTriggerHandler extends TriggerHandler {
    // 28FEB19 - Added static variable to improve performance
    public static boolean MDCTriggerUpdateFlag = false;
    public static boolean MDCTriggerInsertFlag = false;
    public static boolean MDCTriggerDeleteFlag = false; // DEF#661 - 21APR19

    //Added variable to store MDC tickets query which is used in multiple methods
    private static final String mdcTicketsQuery
        = 'SELECT Id, CMPL123__Related_Record_Detail__c, Is_Evaluator_Investigator__c, '
            + 'Is_Medical_Evaluator__c, Is_Prod_Eval_Assessor__c, Is_Quality_Assignee__c, '
            + 'Is_Quality_Non_Complaint__c, Is_Adhoc_Qualty_NonComplaint_Observation__c, '
            + 'Is_Adhoc_Observation_Assignee__c, CMPL123__All_Acks_Received__c, '
            + 'Related_Ticket_Id__c, CMPL123__Audit_Trail_Entry__c, CMPL123__Description__c, '
            + 'CMPL123__Related_Record_ID__c, CMPL123__Related_Record_Name__c '
            + 'FROM CMPL123__MDC_Ticket__c ';

    //Added static maps which used to populate CMPL123__Related_Record_ID__c and Related_Ticket_Id__c
    //fields in before insert event to avoid trigger recursion
    private static Map <String, String> sObjectAPINameByIdPrefix = new Map <String, String> ();
    private static Map <String, String> lookupAPINameByIdPrefix = new Map <String, String> ();
    /**
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic of before insert event and update MDCs' records values.
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void beforeInsert () {
        executeLogicFromWFRules();
        populateMDCTicketsWithRelatedTicketIds(Trigger.new);
    }

    /**
    * @Method       : afterInsert
    * @Invoke       : Events from TriggerHandler after insert
    * @Description  : To handle all the logic in after insert event,  to set flags related to MDC on ticket.
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void afterInsert () {
        system.debug('inside another enqueue---->');
        //Defect #151 fix BEGIN
        //Moved to async apex to avoid exception thrown while executing same trigger twice within the same transaction.
        System.enqueueJob(new ADDMDCTicketUpdateAsync(Trigger.newMap.keySet()));
        //Defect #151 fix END
        Set <Id> mdcTicketIds = Trigger.newMap.keySet();
        List <CMPL123__MDC_Ticket__c> mdcTickets = getMDCTicketsById(mdcTicketIds);
        Set <String> cmsNextTicketNumbers = getCMSNextTicketNumbers(mdcTickets);
        List <CMPL123CME__Complaint__c> relatedTickets = getTicketsByCMSNextTicketNumbers(cmsNextTicketNumbers);
        Map <String, Id> ticketsByRegistrationTicketNumber = groupTicketsByRegistrationTicketNumber(relatedTickets);
        List <CMPL123CME__Complaint__c> ticketsWithConfiguredMDCFlags = getTicketsWithConfiguredMDCFlags(
            mdcTickets,
            ticketsByRegistrationTicketNumber,
            true,
            false
        );
        if (!ticketsWithConfiguredMDCFlags.isEmpty()) {
            try {
                MDCTriggerUpdateFlag = true;
                MDCTriggerInsertFlag = true;
                update ticketsWithConfiguredMDCFlags;
            } catch (Exception ex) {
                System.debug('System was not able to update MDCs flags on given tickets!');
                System.debug(ex);
            } finally {
                MDCTriggerUpdateFlag = false;
                MDCTriggerInsertFlag = false;
            }
        }
        //Added - W-000431
        sendMailToGroup(mdcTicketIds);
    }

    /*
    * @Method       : beforeUpdate.
    * @Invoke       : Events from TriggerHandler before update.
    * @Description  : To handle all the logic in before update event.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeUpdate () {
        // TWD Upgrade issue - FIX START
        executeLogicFromWFRules();
        // TWD Upgrade issue - FIX END
    }

    /**
    * @Method       : afterUpdate
    * @Invoke       : Events from TriggerHandler after update
    * @Description  : To handle all the logic in after update event, to set flags related to MDC on ticket.
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void afterUpdate () {
        List <CMPL123__MDC_Ticket__c> newlyAckMDCTickets = getNewlyAckMDCTickets(
            (Map <Id, CMPL123__MDC_Ticket__c>) Trigger.newMap,
            (Map <Id, CMPL123__MDC_Ticket__c>) Trigger.oldMap
        );
        Set <String> cmsNextTicketNumbers = getCMSNextTicketNumbers(newlyAckMDCTickets);
        List <CMPL123CME__Complaint__c> relatedTickets = getTicketsByCMSNextTicketNumbers(cmsNextTicketNumbers);
        Map <String, Id> ticketsByRegistrationTicketNumber = groupTicketsByRegistrationTicketNumber(relatedTickets);
        List <CMPL123__MDC_Ticket__c> mdcsForRelatedTickets = getMDCTicketsForRelatedTickets(relatedTickets);
        List <CMPL123CME__Complaint__c> ticketsWithConfiguredMDCFlags = getTicketsWithConfiguredMDCFlags(
            mdcsForRelatedTickets,
            ticketsByRegistrationTicketNumber,
            false,
            true
        );
        if (!ticketsWithConfiguredMDCFlags.isEmpty()) {
            try {
                MDCTriggerUpdateFlag = true;
                update ticketsWithConfiguredMDCFlags;
            } catch (Exception ex) {
                System.debug('System was not able to update MDCs flags on given tickets!');
                System.debug(ex);
            } finally {
                MDCTriggerUpdateFlag = false;
            }
        }
    }

    /**
    * @Method       : afterDelete
    * @Invoke       : Events from TriggerHandler after delete
    * @Description  : To handle all the logic in after delete event,m  to set flags related to MDC on ticket After delete.
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void afterDelete () {

        Set<String> relatedTicketIds = new Set<String>();
        Map<Id, CMPL123CME__Complaint__c> updatableTicketMap = new Map<Id, CMPL123CME__Complaint__c>();
        Map<Id, AggregateResult> ticketWithAggregateMap = new Map<Id, AggregateResult>();

        for (CMPL123__MDC_Ticket__c mdcTicket : (List<CMPL123__MDC_Ticket__c>)Trigger.old) {
            if (mdcTicket.Related_Ticket_Id__c != null) {
                relatedTicketIds.add(mdcTicket.Related_Ticket_Id__c);
            }
        }
        for (AggregateResult ar :[SELECT Related_Ticket_Id__c,
                                  SUM(Prod_Eval_Assessor__c) pendingProdEval, SUM(Medical_Evaluator__c) pendingMedical,
                                  SUM(Evaluator_Investigator__c) pendingInvestigator, SUM(Quality_Assignee__c) pendingQuality, SUM(Quality_Non_Complaint__c) pendingNonQuality
                                  FROM CMPL123__MDC_Ticket__c WHERE Related_Ticket_Id__c IN :relatedTicketIds GROUP BY Related_Ticket_Id__c]){
                                      ticketWithAggregateMap.put((Id)ar.get('Related_Ticket_Id__c'), ar);
                                  }

        for (CMPL123__MDC_Ticket__c mdcTicket : (List<CMPL123__MDC_Ticket__c>)Trigger.old) {
            Id ticketId = mdcTicket.Related_Ticket_Id__c != null ? (Id)mdcTicket.Related_Ticket_Id__c : null;

            if (ticketId != null && ticketWithAggregateMap.get(ticketId) != null) {

                CMPL123CME__Complaint__c updatableTicket
                    = updatableTicketMap.get(ticketId) != null
                    ? updatableTicketMap.get(ticketId)
                    : new CMPL123CME__Complaint__c(Id = ticketId);

                AggregateResult ar = ticketWithAggregateMap.get(ticketId);

                if (mdcTicket.Is_Medical_Evaluator__c && Integer.valueOf(ar.get('pendingMedical')) == 0) {
                    updatableTicket.put('Med_Evaluator_Pending_MDCs__c', false);
                }
                updatableTicketMap.put(ticketId, updatableTicket);
            }
        }
        if (updatableTicketMap.keyset().size() > 0) {
            MDCTriggerDeleteFlag = true;    // DEF#661 - 21APR19
            update updatableTicketMap.values();
            MDCTriggerDeleteFlag = false;   // DEF#661 - 21APR19
        }
    }

    /**
    * @Method       : sendMailToGroup
    * @Invoke       : from ADDMDCTicketTriggerHandler class
    * @Description  : To handle all the logic in after delete event. Private method used to send mail to group if inactive
    *                 one or more inactive user present in the group (W-000431).
    * @Return       : N/A
    * @Params       : N/A
    **/
    private static void sendMailToGroup (Set <Id> mdcTicketIds){
        // Check the group name for the selected record
        List<CMPL123__MDC_Ticket__c> lstMDCTickets = [
            SELECT CMPL123__Related_Record_ID__c, CMPL123__Related_Record_Detail__c, CMPL123__Record_Type__c,
                   CMPL123__Field_Name__c, Id, Name, Selected_Group_Name__c
            FROM CMPL123__MDC_Ticket__c
            WHERE Id IN : mdcTicketIds
        ];
        Map<String, List<CMPL123__MDC_Ticket__c>> mapMDCTickets = new Map<String, List<CMPL123__MDC_Ticket__c>>();
        for(CMPL123__MDC_Ticket__c objMDCTicket : lstMDCTickets){
            if(!mapMDCTickets.containsKey(objMDCTicket.Selected_Group_Name__c)){
                mapMDCTickets.put(objMDCTicket.Selected_Group_Name__c, New List<CMPL123__MDC_Ticket__c>{objMDCTicket});
            }else{
                mapMDCTickets.get(objMDCTicket.Selected_Group_Name__c).add(objMDCTicket);
            }
        }

        Map<String, Set<Id>> mapGroupUserIds = New Map<String, Set<Id>>();
        Set<Id> setAllUserIds = New Set<Id>();

        String userType = Schema.SObjectType.User.getKeyPrefix();
        for(GroupMember objGroupMember : [SELECT Group.Name, UserOrGroupId FROM GroupMember WHERE Group.Name IN: mapMDCTickets.keySet()]){
            if(String.valueOf(objGroupMember.UserOrGroupId).startsWith(userType)){
                setAllUserIds.add(objGroupMember.UserOrGroupId);
                if(!mapGroupUserIds.containsKey(objGroupMember.Group.Name)){
                    mapGroupUserIds.put(objGroupMember.Group.Name, New Set<Id>{objGroupMember.UserOrGroupId});
                }else{
                    mapGroupUserIds.get(objGroupMember.Group.Name).add(objGroupMember.UserOrGroupId);
                }
            }
        }

        Set<Id> setUserIds = new Set<Id>();

        if(setAllUserIds.size() > 0){
            for(User objUser : [SELECT Id, isActive FROM User WHERE Id IN: setAllUserIds AND isActive = false]){
                setUserIds.add(objUser.Id);
            }
        }
        Set<String> setGroupNames = New Set<String>();
        for(String strKey : mapGroupUserIds.keySet()){
            for(Id keyId : setUserIds){
                if(mapGroupUserIds.get(strKey).contains(keyId)){
                    setGroupNames.add(strKey);
                }
            }
        }

        // all group with atleast 1 inactive user setGroupNames
        List<Messaging.SingleEmailMessage> lstMessageSingle = new List<Messaging.SingleEmailMessage>();
        String joinedString = '';
        for(String strName :setGroupNames) {
            joinedString += (joinedString==''?'':',')+strName;
        }
        setGroupNames.add('Business Admin');
        if(String.isNotEmpty(joinedString)) {
            for(Contact objContact : [SELECT Id,Lastname,Email FROM Contact WHERE Lastname IN: setGroupNames AND Type__c = 'Group Contact']){
                if(objContact.LastName == 'Business Admin') {
                    String messageBodyForBusinessAdmin = '<html><body>Hello,<br/>One or more inactive user in the group <b>'+joinedString+'</b><br/>Thanks<br/>CHaRM</body></html>';
                    Messaging.SingleEmailMessage objsingleEmailMessageForBusinessAdmin = new  Messaging.SingleEmailMessage();
                    objsingleEmailMessageForBusinessAdmin.setTargetObjectId(objContact.Id);
                    objsingleEmailMessageForBusinessAdmin.setSubject('MDC Ticket created for the group '+joinedString);
                    objsingleEmailMessageForBusinessAdmin.setHtmlBody(messageBodyForBusinessAdmin);

                    lstMessageSingle.add(objsingleEmailMessageForBusinessAdmin);
                } else {
                    for(CMPL123__MDC_Ticket__c objMDCTicket : mapMDCTickets.get(objContact.LastName)){
                        String messageBody = '<html><body>Hello,<br/>Acknowledge this MDC Ticket <br/> <a target="_blank" href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+objMDCTicket.Id+'">Click here</a><br/><br/>Thanks<br/>CHaRM</body></html>';

                        Messaging.SingleEmailMessage objsingleEmailMessage = new  Messaging.SingleEmailMessage();
                        objsingleEmailMessage.setTargetObjectId(objContact.Id);
                        objsingleEmailMessage.setSubject('Acknowledge MDC Ticket');
                        objsingleEmailMessage.setHtmlBody(messageBody);

                        lstMessageSingle.add(objsingleEmailMessage);
                    }
                }
            }
        }

        if(lstMessageSingle.size() > 0){
            Messaging.sendEmail(lstMessageSingle);
        }
    }

    /**
    * @Method       : getCMSNextTicketNumbers
    * @Invoke       : Events from TriggerHandler
    * @Description  : To get a set of impacted CMSNext Ticket Numbers
    * @Return       : Set <String>
    * @Params       : List <CMPL123__MDC_Ticket__c> mdcTickets
    **/
    private static Set <String> getCMSNextTicketNumbers (List <CMPL123__MDC_Ticket__c> mdcTickets) {
        Set <String> cmsNextTicketNumbers = new Set <String> ();
        for (CMPL123__MDC_Ticket__c mdcTicket : mdcTickets) {
            if (String.isNotBlank(mdcTicket.CMPL123__Related_Record_Detail__c)
                && mdcTicket.CMPL123__Related_Record_Detail__c.contains('(')
                && String.isNotBlank(mdcTicket.CMPL123__Related_Record_Detail__c.substringBefore('('))) {
                cmsNextTicketNumbers.add(mdcTicket.CMPL123__Related_Record_Detail__c.substringBefore('('));
            } else {
                mdcTicket.addError('MDC Ticket is missing CMSNext Ticket Number!');
            }
        }
        return cmsNextTicketNumbers;
    }

    /**
    * @Method       : getTicketsByCMSNextTicketNumbers
    * @Invoke       : Events from TriggerHandler
    * @Description  : To get a list of impacted tickets
    * @Return       : List <CMPL123CME__Complaint__c>
    * @Params       : Set <String> cmsNextTicketNumbers
    **/
    private static List <CMPL123CME__Complaint__c> getTicketsByCMSNextTicketNumbers (Set <String> cmsNextTicketNumbers) {
        return [
            SELECT Id, Registration_Ticket__c, CMSNext_Ticket_ID__c
            FROM CMPL123CME__Complaint__c
            WHERE CMSNext_Ticket_ID__c IN :cmsNextTicketNumbers
        ];
    }

    /**
    * @Method       : groupTicketsByRegistrationTicketNumber
    * @Invoke       : Events from TriggerHandler
    * @Description  : To create a map Registration Ticket Number -> Ticket Id
    * @Return       : Map <String, Id>
    * @Params       : List <CMPL123CME__Complaint__c> tickets
    **/
    private static Map <String, Id> groupTicketsByRegistrationTicketNumber (List <CMPL123CME__Complaint__c> tickets) {
        Map <String, Id> ticketsByRegistrationTicketNumber = new Map <String, Id> ();
        for (CMPL123CME__Complaint__c ticket : tickets) {
            ticketsByRegistrationTicketNumber.put(ticket.Registration_Ticket__c, ticket.Id);
        }
        return ticketsByRegistrationTicketNumber;
    }

    /**
    * @Method       : getTicketsWithConfiguredMDCFlags
    * @Invoke       : Events from TriggerHandler
    * @Description  : To set MDC flags on impacted tickets
    * @Return       : List <CMPL123CME__Complaint__c>
    * @Params       : List <CMPL123__MDC_Ticket__c> mdcTickets
    *                 Map <String, Id> ticketsByRegistrationTicketNumber
    *                 Boolean isAfterInsert
    *                 Boolean isAfterUpdate
    **/
    private static List <CMPL123CME__Complaint__c> getTicketsWithConfiguredMDCFlags (
        List <CMPL123__MDC_Ticket__c> mdcTickets,
        Map <String, Id> ticketsByRegistrationTicketNumber,
        Boolean isAfterInsert,
        Boolean isAfterUpdate
    ) {
        Map <String, CMPL123CME__Complaint__c> ticketsByIdWithConfiguredFlags = new Map <String, CMPL123CME__Complaint__c> ();
        Map <String, String> mdcTicketPublicGroupToTicketFlagsMapping = new Map <String, String> {
            'Is_Evaluator_Investigator__c' => 'Evaluator_Investigator_Pending_MDCs__c',
            'Is_Medical_Evaluator__c' => 'Med_Evaluator_Pending_MDCs__c',
            'Is_Prod_Eval_Assessor__c' => 'Prod_Eval_Assessor_Pending_MDCs__c',
            'Is_Quality_Assignee__c' => 'FA_Quality_Assignee_Pending_MDCs__c',
            'Is_Quality_Non_Complaint__c' => 'Quality_Non_Complaint_Pending_MDCs__c', //Added : W-000150
            'Is_Adhoc_Qualty_NonComplaint_Observation__c' => 'Adhoc_Quality_Non_Complaint_Pending_MDCs__c',
            'Is_Adhoc_Observation_Assignee__c' => 'Adhoc_Observation_Assignee_Pending_MDCs__c'
        };
        if (isAfterInsert) {
            for (CMPL123__MDC_Ticket__c mdcTicket : mdcTickets) {
                CMPL123CME__Complaint__c ticketToConfigure = new CMPL123CME__Complaint__c ();
                if (ticketsByIdWithConfiguredFlags.containsKey(mdcTicket.Related_Ticket_Id__c)) {
                    ticketToConfigure = ticketsByIdWithConfiguredFlags.get(mdcTicket.Related_Ticket_Id__c);
                } else {
                    ticketToConfigure.Id = mdcTicket.Related_Ticket_Id__c;
                }
                if (!mdcTicket.CMPL123__All_Acks_Received__c) {
                    for (String mdcTicketGroupFlag : mdcTicketPublicGroupToTicketFlagsMapping.keySet()) {
                        if (mdcTicket.get(mdcTicketGroupFlag) == true) {
                            String ticketFlag = mdcTicketPublicGroupToTicketFlagsMapping.get(mdcTicketGroupFlag);
                            ticketToConfigure.put(ticketFlag, true);
                            break;
                        }
                    }
                }
                ticketToConfigure.put('MDC_Last_Updated_Date__c', System.today());//Defect #179 added by Neeraj
                ticketsByIdWithConfiguredFlags.put(mdcTicket.Related_Ticket_Id__c, ticketToConfigure);
            }
        } else if (isAfterUpdate) {
            List <AggregateResult> mdcTicketsSummaryByTicketId = getMDCTicketsSummaryByTicketsIds(ticketsByRegistrationTicketNumber.values());
            Map <String, String> arSumFieldToTicketFieldMapping = new Map <String, String> {
                'sumPPE' => 'Prod_Eval_Assessor_Pending_MDCs__c',
                'sumPME' => 'Med_Evaluator_Pending_MDCs__c',
                'sumPEI' => 'Evaluator_Investigator_Pending_MDCs__c',
                'sumPQA' => 'FA_Quality_Assignee_Pending_MDCs__c',
                'sumPQNC' => 'Quality_Non_Complaint_Pending_MDCs__c',
                'sumPAQNCO' => 'Adhoc_Quality_Non_Complaint_Pending_MDCs__c',
                'sumPAOA' => 'Adhoc_Observation_Assignee_Pending_MDCs__c'
            };
            for (AggregateResult ar : mdcTicketsSummaryByTicketId) {
                CMPL123CME__Complaint__c ticketToConfigure = new CMPL123CME__Complaint__c ();
                String relatedTicketId = (String) ar.get('Related_Ticket_Id__c');
                if (ticketsByIdWithConfiguredFlags.containsKey(relatedTicketId)) {
                    ticketToConfigure = ticketsByIdWithConfiguredFlags.get(relatedTicketId);
                } else {
                    ticketToConfigure.Id = Id.valueOf(relatedTicketId);
                }
                for (String arField : arSumFieldToTicketFieldMapping.keySet()) {
                    Integer countOfPendingMDCs = Integer.valueOf(ar.get(arField));
                    ticketToConfigure.put(
                        arSumFieldToTicketFieldMapping.get(arField),
                        countOfPendingMDCs > 0
                    );
                }
                ticketsByIdWithConfiguredFlags.put(relatedTicketId, ticketToConfigure);
            }
        }
        return ticketsByIdWithConfiguredFlags.values();
    }

    /**
    * @Method       : populateMDCTicketsWithRelatedTicketIds
    * @Invoke       : Before Insert Event from TriggerHandler
    * @Description  : To populate MDC tickets with Related Ticket Ids
    * @Return       : N/A
    * @Params       : List <CMPL123__MDC_Ticket__c> mdcTickets
    *                 Map <String, Id> ticketsByRegistrationTicketNumber
    **/
    private static void populateMDCTicketsWithRelatedTicketIds (List <CMPL123__MDC_Ticket__c> mdcTickets) {
        Map <String, List <CMPL123__MDC_Ticket__c>> mdcTicketsByRelatedRecordIdPrefix = new Map <String, List <CMPL123__MDC_Ticket__c>> ();
        Map <String, Set <Id>> relatedRecordIdsByIdPrefix = new Map <String, Set <Id>> ();
        //Group MDC tickets by CMPL123__Related_Record_ID__c (parent object)
        for (CMPL123__MDC_Ticket__c mdcTicket : mdcTickets) {
            if (String.isNotBlank(mdcTicket.CMPL123__Related_Record_ID__c)) {
                String relatedRecordIdPrefix = mdcTicket.CMPL123__Related_Record_ID__c.left(3);
                List <CMPL123__MDC_Ticket__c> mdcTicketsForCurrentPrefix;
                Set <Id> relatedRecordIdsForCurrentPrefix;
                if (mdcTicketsByRelatedRecordIdPrefix.containsKey(relatedRecordIdPrefix)) {
                    mdcTicketsForCurrentPrefix = mdcTicketsByRelatedRecordIdPrefix.get(relatedRecordIdPrefix);
                    relatedRecordIdsForCurrentPrefix = relatedRecordIdsByIdPrefix.get(relatedRecordIdPrefix);
                } else {
                    mdcTicketsForCurrentPrefix = new List <CMPL123__MDC_Ticket__c> ();
                    relatedRecordIdsForCurrentPrefix = new Set <Id> ();
                }
                mdcTicketsForCurrentPrefix.add(mdcTicket);
                relatedRecordIdsForCurrentPrefix.add(mdcTicket.CMPL123__Related_Record_ID__c);
                mdcTicketsByRelatedRecordIdPrefix.put(relatedRecordIdPrefix, mdcTicketsForCurrentPrefix);
                relatedRecordIdsByIdPrefix.put(relatedRecordIdPrefix, relatedRecordIdsForCurrentPrefix);
            } else {
                mdcTicket.addError('Value of "CMPL123__Related_Record_ID__c" field on MDC Ticket cannot be blank!');
            }
        }
        //Populate maps
        for (String idPrefix : mdcTicketsByRelatedRecordIdPrefix.keySet()) {
            CMPL123__MDC_Ticket__c mdcTicketSample = mdcTicketsByRelatedRecordIdPrefix.get(idPrefix).get(0);
            populateSObjectAPINameByIdPrefixMap(mdcTicketSample.CMPL123__Related_Record_ID__c);
            populateLookupAPINameByIdPrefixMap(mdcTicketSample.CMPL123__Related_Record_ID__c);
        }
        //Query complaint information. Implemented using anti-pattern to avoid trigger looping
        Map <Id, sObject> parentsWithTicketsByParentId = new Map <Id, SObject> ();
        for (String idPrefix : mdcTicketsByRelatedRecordIdPrefix.keySet()) {
            String sObjectAPIName = sObjectAPINameByIdPrefix.get(idPrefix);
            String relationAPIName;
            String dbQuery;
            Set <Id> relatedRecordIdsForCurrentPrefix = relatedRecordIdsByIdPrefix.get(idPrefix);
            switch on sObjectAPIName {
                when 'CMPL123CME__Complaint__c' {
                    dbQuery = 'SELECT Id, Registration_Ticket__c ';
                }
                when 'Regulatory_Task__c' {
                    dbQuery = 'SELECT Id, EU_MIR__c, EU_MIR__r.CMPL123CME__Complaint__r.Registration_Ticket__c,'+
                        ' MDI__r.CMPL123CME__Complaint__r.Registration_Ticket__c, '
                              + 'MDI__r.CMPL123CME__Complaint__r.Id ';
                }
                //Defect #33 additional fix BEGIN
                when 'Attachment__c' {
                    dbQuery = 'SELECT Id, '
                              + 'Customer_Response__c, Customer_Response__r.Event__r.Registration_Ticket__c, '
                              + 'Customer_Response__r.Event__r.Id, '
                              + 'Evaluation_Investigation_Task__c, Evaluation_Investigation_Task__r.Parent_Ticket__r.Registration_Ticket__c, '
                              + 'Evaluation_Investigation_Task__r.Parent_Ticket__r.Id, '
                              + 'Investigation_Evaluation__c, Investigation_Evaluation__r.CMPL123CME__Complaint__r.Registration_Ticket__c, '
                              + 'Investigation_Evaluation__r.CMPL123CME__Complaint__r.Id, '
                              + 'MEDDEV__c, MEDDEV__r.CMPL123CME__Complaint__r.Registration_Ticket__c, '
                              + 'MEDDEV__r.CMPL123CME__Complaint__r.Id, '
                              + 'Assessment__c, Assessment__r.CMPL123CME__Complaint__r.Registration_Ticket__c, '
                              + 'Assessment__r.CMPL123CME__Complaint__r.Id, '
                              + 'Medical_Evaluation_Task__c, Medical_Evaluation_Task__r.Parent_Ticket__r.Registration_Ticket__c, '
                              + 'Medical_Evaluation_Task__r.Parent_Ticket__r.Id, '
                              + 'Regulatory_Task__c, Regulatory_Task__r.MDI__r.CMPL123CME__Complaint__r.Registration_Ticket__c, '
                              + 'Regulatory_Task__r.MDI__r.CMPL123CME__Complaint__r.Id, '
                              + 'Return__c, Return__r.Ticket__r.Registration_Ticket__c, '
                              + 'Return__r.Ticket__r.Id, '
                              + 'Ticket__c, Ticket__r.Registration_Ticket__c, '
                              + 'Ticket__r.Id ';
                }
                when 'Medical_Evaluation_Task__c' {
                    dbQuery = 'SELECT Id, Medical_Evaluation__c, '
                              + 'Medical_Evaluation__r.CMPL123CME__Complaint__r.Registration_Ticket__c, '
                              + 'Medical_Evaluation__r.CMPL123CME__Complaint__r.Id ';
                }
                when 'Patient_Information__c', 'pRE_Question__c' {
                    dbQuery = 'SELECT Id, pRE_Information__c, '
                              + 'pRE_Information__r.Complaint__r.Registration_Ticket__c, '
                              + 'pRE_Information__r.Complaint__r.Id ';
                }
                when 'Product_Lot__c' {
                    dbQuery = 'SELECT Id, Product_Evaluation_Investigation__c, '
                              + 'Product_Evaluation_Investigation__r.CMPL123CME__Complaint__r.Registration_Ticket__c, '
                              + 'Product_Evaluation_Investigation__r.CMPL123CME__Complaint__r.Id ';
                }
                //Defect #33 additional fix END
                when else {
                    relationAPIName = lookupAPINameByIdPrefix.get(idPrefix).replace('__c', '__r');
                    dbQuery = 'SELECT Id, ' + relationAPIName + '.Registration_Ticket__c, '
                               + relationAPIName + '.Id ';
                }
            }
            dbQuery += 'FROM ' + sObjectAPIName + ' '
                    + 'WHERE Id IN :relatedRecordIdsForCurrentPrefix';
            parentsWithTicketsByParentId.putAll(Database.query(dbQuery));
        }
        //Update MDC Tickets
        for (CMPL123__MDC_Ticket__c mdcTicket : mdcTickets) {
            String relatedRecordIdPrefix = mdcTicket.CMPL123__Related_Record_ID__c.left(3);
            String sObjectAPIName = sObjectAPINameByIdPrefix.get(relatedRecordIdPrefix);
            sObject parentWithTicketInfo = parentsWithTicketsByParentId.get(mdcTicket.CMPL123__Related_Record_ID__c);
            sObject parentTicket;
            switch on sObjectAPIName {
                when 'CMPL123CME__Complaint__c' {
                    mdcTicket.CMPL123__Related_Record_Detail__c = (String) parentWithTicketInfo.get('Registration_Ticket__c');
                    mdcTicket.Related_Ticket_Id__c = (String) parentWithTicketInfo.get('Id');
                }
                //@Juneid 1 Sep 2021, Defect 29 Fixed Apllied
                //@Junied 16 Sep 2021, MDC Logic added for MIR
                when 'Regulatory_Task__c' {
                    if(parentWithTicketInfo.getSObject('MDI__r') != null && parentWithTicketInfo.getSObject('MDI__r').getSObject('CMPL123CME__Complaint__r') != null){
                        parentTicket = parentWithTicketInfo.getSObject('MDI__r')
                                                       .getSObject('CMPL123CME__Complaint__r');
                    }else if(parentWithTicketInfo.getSObject('EU_MIR__r') != null && parentWithTicketInfo.getSObject('EU_MIR__r').getSObject('CMPL123CME__Complaint__r') != null){
                        parentTicket = parentWithTicketInfo.getSObject('EU_MIR__r')
                                                       .getSObject('CMPL123CME__Complaint__r');
                    }                    
                }
                //Defect #33 additional fix BEGIN
                when 'Attachment__c' {
                    //Attachment might be not related to ticket, or it might be either: child; grand child; grand-grand-child of a ticket
                    //Handle case if grand child (most common)
                    Map <String, String> attachmentToTicketRelationAsGrandChild = new Map <String, String> {
                        'Customer_Response__c' => 'Event__r',
                        'Evaluation_Investigation_Task__c' => 'Parent_Ticket__r',
                        'Investigation_Evaluation__c' => 'CMPL123CME__Complaint__r',
                        'MEDDEV__c' => 'CMPL123CME__Complaint__r',
                        'Assessment__c' => 'CMPL123CME__Complaint__r',
                        'Medical_Evaluation_Task__c' => 'Parent_Ticket__r',
                        'Return__c' => 'Ticket__r'
                    };
                    for (String lookupAPIName : attachmentToTicketRelationAsGrandChild.keySet()) {
                        if (String.isNotBlank((String) parentWithTicketInfo.get(lookupAPIName))) {
                            String relationAPIName = lookupAPIName.replace('__c', '__r');
                            parentTicket = parentWithTicketInfo.getSObject(relationAPIName);
                        }
                    }
                    //Handle case if child
                    if (parentTicket == null && String.isNotBlank((String) parentWithTicketInfo.get('Ticket__c'))) {
                        parentTicket = parentWithTicketInfo.getSObject('Ticket__r');
                    }
                    //Handle case if grand child
                    if (parentTicket == null && String.isNotBlank((String) parentWithTicketInfo.get('Regulatory_Task__c'))) {
                        parentTicket = parentWithTicketInfo.getSObject('Regulatory_Task__r')
                                                           .getSObject('MDI__r')
                                                           .getSObject('CMPL123CME__Complaint__r');
                    }
                    //To create MDC attachment should be realted to ticket
                    if (parentTicket == null) {
                        mdcTicket.addError('Cannot create regulatory attachment for object which is not a ticket child!');
                    }
                }
                when 'Medical_Evaluation_Task__c' {
                    parentTicket = parentWithTicketInfo.getSObject('Medical_Evaluation__r')
                                                       .getSObject('CMPL123CME__Complaint__r');
                }
                when 'Patient_Information__c', 'pRE_Question__c' {
                    parentTicket = parentWithTicketInfo.getSObject('pRE_Information__r')
                                                       .getSObject('Complaint__r');
                }
                when 'Product_Lot__c' {
                    parentTicket = parentWithTicketInfo.getSObject('Product_Evaluation_Investigation__r')
                                                       .getSObject('CMPL123CME__Complaint__r');
                }
                //Defect #33 additional fix END
                when else {
                    String relationAPIName = lookupAPINameByIdPrefix.get(relatedRecordIdPrefix).replace('__c', '__r');
                    parentTicket = parentWithTicketInfo.getSObject(relationAPIName);
                }
            }
            if (parentTicket == null) {
                if (sObjectAPIName != 'CMPL123CME__Complaint__c') {
                    mdcTicket.addError('Cannot determine parent ticket!');
                }
            } else {
                mdcTicket.CMPL123__Related_Record_Detail__c = (String) parentTicket.get('Registration_Ticket__c');
                mdcTicket.Related_Ticket_Id__c = (String) parentTicket.get('Id');
            }
        }
    }

    /**
    * @Method       : getNewlyAckMDCTickets
    * @Invoke       : From After Update Event from TriggerHandler
    * @Description  : To get only Acknowledged MDC tickets
    * @Return       : N/A
    * @Params       : Map <Id, CMPL123__MDC_Ticket__c> newMDCTicketsMap
    *                 Map <Id, CMPL123__MDC_Ticket__c> oldMDCTicketsMap
    **/
    private static List <CMPL123__MDC_Ticket__c> getNewlyAckMDCTickets (Map <Id, CMPL123__MDC_Ticket__c> newMDCTicketsMap, Map <Id, CMPL123__MDC_Ticket__c> oldMDCTicketsMap) {
        List <CMPL123__MDC_Ticket__c> mdcTicketsWithChangedACKs = new List <CMPL123__MDC_Ticket__c> ();
        for (CMPL123__MDC_Ticket__c mdcTicket : newMDCTicketsMap.values()) {
            if (mdcTicket.CMPL123__All_Acks_Received__c != oldMDCTicketsMap.get(mdcTicket.Id).CMPL123__All_Acks_Received__c
                && mdcTicket.CMPL123__All_Acks_Received__c) {
                mdcTicketsWithChangedACKs.add(mdcTicket);
            }
        }
        return mdcTicketsWithChangedACKs;
    }

    /**
    * @Method       : getMDCTicketsForRelatedTickets
    * @Invoke       : Events from TriggerHandler
    * @Description  : To get MDC tickets related to given list of tickets
    * @Return       : List <CMPL123__MDC_Ticket__c>
    * @Params       : List <CMPL123CME__Complaint__c> relatedTickets
    **/
    private static List <CMPL123__MDC_Ticket__c> getMDCTicketsForRelatedTickets (List <CMPL123CME__Complaint__c> relatedTickets) {
        Set <Id> relatedTicketsIds = (new Map <Id, CMPL123CME__Complaint__c> (relatedTickets)).keySet();
        return Database.query(mdcTicketsQuery + 'WHERE Related_Ticket_Id__c IN :relatedTicketsIds');
    }

    /**
    * @Method       : getMDCTicketsById
    * @Invoke       : Events from TriggerHandler
    * @Description  : To get a list of MDC tickets by their Ids
    * @Return       : List <CMPL123__MDC_Ticket__c>
    * @Params       : Set <Id> mdcTicketIds
    **/
    private static List <CMPL123__MDC_Ticket__c> getMDCTicketsById (Set <Id> mdcTicketIds) {
        return Database.query(mdcTicketsQuery + 'WHERE Id IN :mdcTicketIds');
    }

    /**
    * @Method       : getMDCTicketsSummaryByTicketsIds
    * @Invoke       : Events from TriggerHandler
    * @Description  : To get a list of MDC tickets by their Ids
    * @Return       : AggregateResult
    * @Params       : Set <Id> mdcTicketIds
    **/
    private static List <AggregateResult> getMDCTicketsSummaryByTicketsIds (List <Id> ticketIds) {
        return [
            SELECT Related_Ticket_Id__c,
                   SUM(Prod_Eval_Assessor__c) sumPPE, SUM(Medical_Evaluator__c) sumPME,
                   SUM(Evaluator_Investigator__c) sumPEI, SUM(Quality_Assignee__c) sumPQA,
                   SUM(Quality_Non_Complaint__c) sumPQNC, SUM(Adhoc_Quality_Non_Complaint_Observation__c) sumPAQNCO,
                   SUM(Adhoc_Observation_Assignee__c) sumPAOA
            FROM CMPL123__MDC_Ticket__c
            WHERE Related_Ticket_Id__c IN :ticketIds
            GROUP BY Related_Ticket_Id__c
        ];
    }

    /*
    * @Method       : executeLogicFromWFRules.
    * @Description  : TWD Upgrade issue - this method contains logic from Workflow Rules with Field Updates on MDC Ticket.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void executeLogicFromWFRules() {
        List<CMPL123__MDC_Ticket__c> newList = (List<CMPL123__MDC_Ticket__c>) Trigger.new;
        Map<Id, CMPL123__MDC_Ticket__c> oldMap = (Map<Id, CMPL123__MDC_Ticket__c>) Trigger.oldMap;

        Set<Id> mdcTriggerIds = new Set<Id>();

        for (CMPL123__MDC_Ticket__c newMDCTicket :newList) {
            if (null != newMDCTicket.CMPL123__MDC_Trigger__c) {
                mdcTriggerIds.add(newMDCTicket.CMPL123__MDC_Trigger__c);
            }
        }

        Map<Id, CMPL123__MDC_Trigger__c> mdcTriggers = new Map<Id, CMPL123__MDC_Trigger__c>([
            SELECT Id, CMPL123__Description__c
            FROM CMPL123__MDC_Trigger__c
            WHERE Id IN :mdcTriggerIds
        ]);

        for (CMPL123__MDC_Ticket__c newMDCTicket :newList) {
            //  MDC Ticket Description
            if (null != newMDCTicket.Name && newMDCTicket.CMPL123__All_Acks_Received__c == false) {
                newMDCTicket.CMPL123__Description__c = null != newMDCTicket.CMPL123__MDC_Trigger__c
                    ? mdcTriggers.get(newMDCTicket.CMPL123__MDC_Trigger__c).CMPL123__Description__c
                    : newMDCTicket.CMPL123__Description__c;
            }
        }
    }

    /*
    * @Method       : populateSObjectAPINameByIdPrefixMap.
    * @Description  : Utility method which needed to get API Name of SObject by its recod Id.
    * @Return       : N/A.
    * @Params       : Id recordId.
    */
    private static void populateSObjectAPINameByIdPrefixMap (Id recordId) {
        String idPrefix = String.valueOf(recordId).left(3);
        if (!sObjectAPINameByIdPrefix.containsKey(idPrefix)) {
            sObjectAPINameByIdPrefix.put(idPrefix, recordId.getSobjectType().getDescribe().getName());
        }
    }

    /*
    * @Method       : populateLookupAPINameByIdPrefixMap.
    * @Description  : Utility method which needed to get API Name of a lookup to Complaint field by its recod Id.
    * @Return       : N/A.
    * @Params       : Id recordId.
    */
    private static void populateLookupAPINameByIdPrefixMap (Id recordId) {
        String idPrefix = String.valueOf(recordId).left(3);
        if (!lookupAPINameByIdPrefix.containsKey(idPrefix)) {
            for (SObjectField sObjectField : recordId.getSobjectType().getDescribe().fields.getMap().values()) {
                Schema.DescribeFieldResult fieldDescription = sObjectField.getDescribe();
                Schema.DisplayType fieldType = fieldDescription.getType();
                List <Schema.sObjectType> fieldReferences = fieldDescription.getReferenceTo();
                Schema.SObjectType complaintsObjectType = Schema.SObjectType.CMPL123CME__Complaint__c.getsObjectType();
                if (String.valueOf(fieldType) == 'REFERENCE' && fieldReferences.contains(complaintsObjectType)) {
                    lookupAPINameByIdPrefix.put(idPrefix, fieldDescription.getName());
                    break;
                }
            }
        }
    }

    /**
    * --------------------------------------------------------------------------------------------------------------------------------------
    * @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
    * @What  : ADDMDCTicketUpdateAsync
    * @Why   : To move logic related to ticket update into a queue
    * @When  : 09-FEB-2021
    * @Where : From ADDMDCTicketTriggerHandler Trigger
    * --------------------------------------------------------------------------------------------------------------------------------------
    * Modification Log:
    * --------------------------------------------------------------------------------------------------------------------------------------
    * Developer                Date                   Modification ID      Description
    * --------------------------------------------------------------------------------------------------------------------------------------
    * RSlob                    09-FEB-2021            Defect #151          Created.
    * --------------------------------------------------------------------------------------------------------------------------------------
    **/
    private class ADDMDCTicketUpdateAsync implements Queueable {

        Set <Id> mdcTicketIds;

        /*
        * @Method       : ADDMDCTicketUpdateAsync.
        * @Description  : Custom constructor.
        * @Return       : N/A.
        * @Params       : Set <Id> mdcTicketIds.
        */
        public ADDMDCTicketUpdateAsync (Set <Id> mdcTicketIds) {
            this.mdcTicketIds = mdcTicketIds;
        }

        /*
        * @Method       : execute.
        * @Description  : Contains queue logic.
        * @Return       : N/A.
        * @Params       : QueueableContext cxt.
        */
        public void execute (QueueableContext cxt) {
            List <CMPL123__MDC_Ticket__c> mdcTickets = getMDCTicketsById(mdcTicketIds);
            Set <String> cmsNextTicketNumbers = getCMSNextTicketNumbers(mdcTickets);
            List <CMPL123CME__Complaint__c> relatedTickets = getTicketsByCMSNextTicketNumbers(cmsNextTicketNumbers);
            Map <String, Id> ticketsByRegistrationTicketNumber = groupTicketsByRegistrationTicketNumber(relatedTickets);
            List <CMPL123CME__Complaint__c> ticketsWithConfiguredMDCFlags = getTicketsWithConfiguredMDCFlags(
                mdcTickets,
                ticketsByRegistrationTicketNumber,
                true,
                false
            );
            if (!ticketsWithConfiguredMDCFlags.isEmpty()) {
                try {
                    MDCTriggerUpdateFlag = true;
                    MDCTriggerInsertFlag = true;
                    update ticketsWithConfiguredMDCFlags;
                } catch (Exception ex) {
                    System.debug('System was not able to update MDCs flags on given tickets!');
                    System.debug(ex);
                } finally {
                    MDCTriggerUpdateFlag = false;
                    MDCTriggerInsertFlag = false;
                }
            }
            //Added - W-000431
            sendMailToGroup(mdcTicketIds);
        }
    }
    //Defect #151 fix END
}