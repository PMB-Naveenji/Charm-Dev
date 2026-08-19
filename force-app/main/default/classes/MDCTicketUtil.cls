/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
 * @What  : MDCTicketUtil
 * @Why   : Util class to insert MDC entries
 * @When  : 23-JUN-2020
 * @Where : From ADDMeaningfulDataTriggerHandler, ADDPatientInformationTriggerHandler classes
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID                  Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                    23-JUN-2020            #124(CHARM-2724)                 Created. Inserting MDC Ticket on Insert of Record.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    08-JUL-2020            Code Audit                       Added header comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                    19-AUG-2020            Code Audit                       Adjusted class/methods headers.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             08-AUG-2022            CHaRM R2.2                       Defect 164: Refactor getParentTicketDetails and 
 * add TICKETFLAG_IS_REPLY_REQUIRED flag as a return value
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             30-JAN-2023            CHaRM R3.0                       Defect 411: Added TICKETFLAG_HAS_ACTIVE_TICKET_SEARCH
 * to the return value for getParentTicketDetails. Misc cleanup
 * --------------------------------------------------------------------------------------------------------------------------------------
*/

public class MDCTicketUtil {
    public static Boolean retrievedTicketInformation = false;
    private static Map<Id, Map<String, Boolean>> ticketInfoCacheMap = new Map<Id, Map<String, Boolean>>();

    /**
     * @Method       : createMDC.
     * @Description  : Inserts new MDC entries.
     * @Invoke       : From MDCTicketUtil Class.
     * @Return       : N/A.
     * @Params       : String mdcTriggerName, Map <Id, sObject> newMap, String relatedTicketIdAPI, String relatedTicketNumberAPI.
     */
    public static void createMDC(String mdcTriggerName, Map<Id, sObject> newMap, String relatedTicketIdAPI,
        String relatedTicketNumberAPI, String auditEntryField, Boolean createJunctionRecord)
    {
        system.debug('mdcTriggerName--->'+mdcTriggerName);
        system.debug('newMap--->'+newMap);
        //'Patient Information Change', Trigger.newMap, 'Complaint__c', 'Registration_Number__c'
        List <CMPL123__Audit_Trail_Entry__c> entries = [
            SELECT Id, CMPL123__ParentId__c, CMPL123__Audit_Trail_JSON__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c IN: newMap.keySet() AND
            CMPL123__Action__c = 'Insert'];
        system.debug('entries--->'+entries);
        List <CMPL123__MDC_Trigger__c> triggers = [
            SELECT Id, Name, CMPL123__Number_of_Acks__c, CMPL123__Select_Target_Object__c, Selected_Group_Name__c
            FROM CMPL123__MDC_Trigger__c
            WHERE Name =: mdcTriggerName];
        system.debug('triggers--->'+triggers);
        system.debug('triggers.size()--->'+triggers.size());

        if (triggers.size() != 1 && !Test.isRunningTest()) {
            throw new IllegalArgumentException(mdcTriggerName + ' does not exist');
        }
        
        if (triggers.size() == 1) {
            List <CMPL123__MDC_Field_Mapping__c> fieldMappings = [
                SELECT Id, CMPL123__Field_API__c, CMPL123__Field_Name__c
                FROM CMPL123__MDC_Field_Mapping__c
                WHERE CMPL123__Parent_object__c =: triggers.get(0).Id];
            List <CMPL123__MDC_Ticket__c> tickets = new List <CMPL123__MDC_Ticket__c>();

            Map <Id, CMPL123__Audit_Trail_Entry__c> entryByParentId = new Map <Id, CMPL123__Audit_Trail_Entry__c>();
            for (CMPL123__Audit_Trail_Entry__c entry: entries) {
                /*@todo research: describe in apex  get all fields of the object,
                describe each field, get type, if long text add it to the list */
                // added by rupesh to get the correct audit trail entry 
                if (entry.CMPL123__Audit_Trail_JSON__c.contains(auditEntryField) ) {
                    entryByParentId.put(entry.CMPL123__ParentId__c, entry);
                }
                // added by rupesh to get the correct audit trail entry 
            }
            for (sObject record: newMap.values()) {
                CMPL123__Audit_Trail_Entry__c auditTrailEntry = entryByParentId.get(record.Id);
                List<String> fieldAPINames = new List <String>();
                List<String> fieldLabels = new List <String>();
                String conditions = '';
                for (CMPL123__MDC_Field_Mapping__c fieldMapping : fieldMappings ) {
                    if (record.get(fieldMapping.CMPL123__Field_API__c) != null &&
                        !fieldAPINames.contains(fieldMapping.CMPL123__Field_API__c))
                    {
                        fieldAPINames.add(fieldMapping.CMPL123__Field_API__c);
                        fieldLabels.add(fieldMapping.CMPL123__Field_Name__c);
                        conditions += 'Custom,';
                    }
                }
                if (conditions.length() > 0) {
                    conditions = conditions.substring(0, conditions.length() - 1);
                }
                if (null != auditTrailEntry) {
                    tickets.add(new CMPL123__MDC_Ticket__c (
                        CMPL123__All_Acks_Received__c = false,
                        CMPL123__Audit_Trail_Entry__c = auditTrailEntry.Id,
                        CMPL123__Description__c = triggers.get(0).Name,
                        CMPL123__Field_Condition__c = conditions,
                        CMPL123__Field_Name__c  = String.join(fieldLabels, ','),
                        CMPL123__MDC_Trigger__c = triggers.get(0).Id,
                        CMPL123__Related_Record_Detail__c = (String) record.get(relatedTicketNumberAPI),
                        CMPL123__Record_Type__c = triggers.get(0).CMPL123__Select_Target_Object__c,
                        CMPL123__Related_Record_ID__c   = record.Id,
                        CMPL123__Related_Record_Name__c = (String) record.get('Name'),
                        Related_Ticket_Id__c = (String) record.get(relatedTicketIdAPI),
                        CMPL123__Rule_Description__c = 'Record has been updated on ' + triggers.get(0).Id)
                    );
                }
            }

            insert tickets;

            //revise code start 
            List <SObject> mdcANDjunction = new List <SObject> ();
            for (CMPL123__MDC_Ticket__c ticket: tickets) {
                mdcANDjunction.add(new CMPL123__MDC_Acknowledgement_Entry__c(
                    CMPL123__MDC_Ticket__c = ticket.Id,
                    CMPL123__Object_Name__c = triggers.get(0).CMPL123__Select_Target_Object__c,
                    CMPL123__Public_Group__c = triggers.get(0).Selected_Group_Name__c,
                    CMPL123__Number_Acknowledgments_Received__c = 0,
                    CMPL123__Required_Acknowledgments__c = triggers.get(0).CMPL123__Number_of_Acks__c ,
                    CMPL123__Type_Of_Acknowledgment__c = 'Public Group')
               );
            }

            if (createJunctionRecord) {
                for (CMPL123__MDC_Ticket__c ticket: tickets) {
                    CMPL123__MDC_Audit__c obj = new CMPL123__MDC_Audit__c();
                    obj.CMPL123__Audit_Trail_Entry__c=ticket.CMPL123__Audit_Trail_Entry__c;
                    obj.CMPL123__MDC_Ticket__c=ticket.id;
                    mdcANDjunction.add(obj);
                }
                insert mdcANDjunction ;
            }
            // revise code end 
       }

    }
    
    public static void createMDCBulk(List<MDCRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }
        
        Set<Id> allParentRecordIds = new Set<Id>();
        Set<String> triggerNames = new Set<String>();
        
        for (MDCRequest req : requests) {
            if (req == null || req.newMap == null || req.newMap.isEmpty()) {
                continue;
            }
            
            allParentRecordIds.addAll(req.newMap.keySet());
            triggerNames.add(req.mdcTriggerName);
        }
        
        if (allParentRecordIds.isEmpty() || triggerNames.isEmpty()) {
            return;
        }
        
        List<CMPL123__Audit_Trail_Entry__c> entries = [
            SELECT Id, CMPL123__ParentId__c, CMPL123__Audit_Trail_JSON__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c IN :allParentRecordIds
            AND CMPL123__Action__c = 'Insert'
        ];
        
        List<CMPL123__MDC_Trigger__c> triggerRecords = [
            SELECT Id,
            Name,
            CMPL123__Number_of_Acks__c,
            CMPL123__Select_Target_Object__c,
            Selected_Group_Name__c
            FROM CMPL123__MDC_Trigger__c
            WHERE Name IN :triggerNames
        ];
        
        Map<String, CMPL123__MDC_Trigger__c> triggerByName = new Map<String, CMPL123__MDC_Trigger__c>();
        
        for (CMPL123__MDC_Trigger__c trig : triggerRecords) {
            triggerByName.put(trig.Name, trig);
        }
        
        if (!Test.isRunningTest()) {
            for (String triggerName : triggerNames) {
                if (!triggerByName.containsKey(triggerName)) {
                    throw new IllegalArgumentException(triggerName + ' does not exist');
                }
            }
        }
        
        Set<Id> triggerIds = new Set<Id>();
        for (CMPL123__MDC_Trigger__c trig : triggerByName.values()) {
            triggerIds.add(trig.Id);
        }
        
        Map<Id, List<CMPL123__MDC_Field_Mapping__c>> fieldMappingsByTriggerId =
            new Map<Id, List<CMPL123__MDC_Field_Mapping__c>>();
        
        for (CMPL123__MDC_Field_Mapping__c mapping : [
            SELECT Id,
            CMPL123__Field_API__c,
            CMPL123__Field_Name__c,
            CMPL123__Parent_object__c
            FROM CMPL123__MDC_Field_Mapping__c
            WHERE CMPL123__Parent_object__c IN :triggerIds
        ]) {
            if (!fieldMappingsByTriggerId.containsKey(mapping.CMPL123__Parent_object__c)) {
                fieldMappingsByTriggerId.put(
                    mapping.CMPL123__Parent_object__c,
                    new List<CMPL123__MDC_Field_Mapping__c>()
                );
            }
            
            fieldMappingsByTriggerId.get(mapping.CMPL123__Parent_object__c).add(mapping);
        }
        
        List<CMPL123__MDC_Ticket__c> allTicketsToInsert = new List<CMPL123__MDC_Ticket__c>();
        
        for (MDCRequest req : requests) {
            if (req == null || req.newMap == null || req.newMap.isEmpty()) {
                continue;
            }
            
            CMPL123__MDC_Trigger__c mdcTrigger = triggerByName.get(req.mdcTriggerName);
            
            if (mdcTrigger == null) {
                continue;
            }
            
            List<CMPL123__MDC_Field_Mapping__c> fieldMappings =
                fieldMappingsByTriggerId.get(mdcTrigger.Id);
            
            if (fieldMappings == null) {
                fieldMappings = new List<CMPL123__MDC_Field_Mapping__c>();
            }
            
            Map<Id, CMPL123__Audit_Trail_Entry__c> entryByParentId =
                new Map<Id, CMPL123__Audit_Trail_Entry__c>();
            
            for (CMPL123__Audit_Trail_Entry__c entry : entries) {
                if (
                    req.newMap.containsKey(entry.CMPL123__ParentId__c) &&
                    entry.CMPL123__Audit_Trail_JSON__c != null &&
                    entry.CMPL123__Audit_Trail_JSON__c.contains(req.auditEntryField)
                ) {
                    entryByParentId.put(entry.CMPL123__ParentId__c, entry);
                }
            }
            
            for (SObject record : req.newMap.values()) {
                CMPL123__Audit_Trail_Entry__c auditTrailEntry =
                    entryByParentId.get((Id)record.get('Id'));
                
                if (auditTrailEntry == null) {
                    continue;
                }
                
                List<String> fieldAPINames = new List<String>();
                List<String> fieldLabels = new List<String>();
                String conditions = '';
                
                for (CMPL123__MDC_Field_Mapping__c fieldMapping : fieldMappings) {
                    String fieldApiName = fieldMapping.CMPL123__Field_API__c;
                    
                    if (
                        record.get(fieldApiName) != null &&
                        !fieldAPINames.contains(fieldApiName)
                    ) {
                        fieldAPINames.add(fieldApiName);
                        fieldLabels.add(fieldMapping.CMPL123__Field_Name__c);
                        conditions += 'Custom,';
                    }
                }
                
                if (conditions.length() > 0) {
                    conditions = conditions.substring(0, conditions.length() - 1);
                }
                
                allTicketsToInsert.add(new CMPL123__MDC_Ticket__c(
                    CMPL123__All_Acks_Received__c = false,
                    CMPL123__Audit_Trail_Entry__c = auditTrailEntry.Id,
                    CMPL123__Description__c = mdcTrigger.Name,
                    CMPL123__Field_Condition__c = conditions,
                    CMPL123__Field_Name__c = String.join(fieldLabels, ','),
                    CMPL123__MDC_Trigger__c = mdcTrigger.Id,
                    CMPL123__Related_Record_Detail__c =
                    String.valueOf(record.get(req.relatedTicketNumberAPI)),
                    CMPL123__Record_Type__c = mdcTrigger.CMPL123__Select_Target_Object__c,
                    CMPL123__Related_Record_ID__c = (Id)record.get('Id'),
                    CMPL123__Related_Record_Name__c = String.valueOf(record.get('Name')),
                    Related_Ticket_Id__c = String.valueOf(record.get(req.relatedTicketIdAPI)),
                    CMPL123__Rule_Description__c =
                    'Record has been updated on ' + mdcTrigger.Id
                ));
            }
        }
        
        if (!allTicketsToInsert.isEmpty()) {
            insert allTicketsToInsert;
        }
        
        List<SObject> mdcAndJunctionRecords = new List<SObject>();
        
        for (CMPL123__MDC_Ticket__c ticket : allTicketsToInsert) {
            CMPL123__MDC_Trigger__c mdcTrigger;
            
            for (CMPL123__MDC_Trigger__c trig : triggerByName.values()) {
                if (trig.Id == ticket.CMPL123__MDC_Trigger__c) {
                    mdcTrigger = trig;
                    break;
                }
            }
            
            if (mdcTrigger == null) {
                continue;
            }
            
            mdcAndJunctionRecords.add(new CMPL123__MDC_Acknowledgement_Entry__c(
                CMPL123__MDC_Ticket__c = ticket.Id,
                CMPL123__Object_Name__c = mdcTrigger.CMPL123__Select_Target_Object__c,
                CMPL123__Public_Group__c = mdcTrigger.Selected_Group_Name__c,
                CMPL123__Number_Acknowledgments_Received__c = 0,
                CMPL123__Required_Acknowledgments__c = mdcTrigger.CMPL123__Number_of_Acks__c,
                CMPL123__Type_Of_Acknowledgment__c = 'Public Group'
            ));
            
            mdcAndJunctionRecords.add(new CMPL123__MDC_Audit__c(
                CMPL123__Audit_Trail_Entry__c = ticket.CMPL123__Audit_Trail_Entry__c,
                CMPL123__MDC_Ticket__c = ticket.Id
            ));
        }
        
        if (!mdcAndJunctionRecords.isEmpty()) {
            insert mdcAndJunctionRecords;
        }
    }
    
    /**
     * Fetches Tickets and some children to determine how to handle MDCs for Tickets
     * @param ticketIds All Ids to determine flags for. If flags were already
     * determined, no query will be done for that Id
     * @return A map of Ticket Ids to a sub-map. Unless the Id does not exist,
     * all Ids in ticketIds should be keys. The sub-map matches descriptive flag
     * names to Booleans. Look at the code to see what keys exist
     * @revision 08-AUG-2022 Larry: Defect 164. Renamed returnMap to ticketIdToFlagMap.
     * Included Customer_Reply_Required__c to the query. Added isReplyRequired
     * to the resulting map. Filled this whole docstring. Replaced all magic words
     * with constants in AspenConstants
     * @revision 30-JAN-2023 Larry: CHaRM R3.0, Defect 411. Added hasActiveTicketSearch
     * as a flag in the returned map of maps. Replaced some magic words with constants
     */
    public static Map<Id, Map<String, Boolean>> getParentTicketDetails (Set<Id> ticketIds) {
        retrievedTicketInformation = true;
        Map<Id, Map<String, Boolean>> ticketIdToFlagMap = new Map<Id, Map<String, Boolean>>();

        Set<Id> ticketIdsToQuery = new Set<Id>();
        // check map cache 
        for (Id ticketId: ticketIds) {
            if (!ticketInfoCacheMap.containsKey(ticketId)) {
                ticketIdsToQuery.add(ticketId);
            } else {
                ticketIdToFlagMap.put(ticketId, ticketInfoCacheMap.get(ticketId) );
            }
        }

        for (CMPL123CME__Complaint__c ticketRecord : queryTicketsAndNonVoidChildren(ticketIdsToQuery)) {
            Map<String, Boolean> tempMap = getFlagMapForTicket(ticketRecord);
            ticketIdToFlagMap.put(ticketRecord.Id, tempMap);
            ticketInfoCacheMap.put(ticketRecord.Id, tempMap);
        }

        return ticketIdToFlagMap;
    }

    /**
     * Queries for Ticket fields and all non-void children that could affect MDC creation.
     * This query was nearly identical in both MDCTicketflagUtil.getParentTicketDetails and
     * TicketQDNumMDCCustom.setDefaults, so this function was made to share the logic.
     * @param ticketIdsToQuery All Ticket ids to query for. Can be null, empty, or have values.
     * @return All queried Tickets.
     * @author 30-JAN-2023 Larry
     */
    public static List<CMPL123CME__Complaint__c> queryTicketsAndNonVoidChildren(Set<Id> ticketIdsToQuery) {
        if (ticketIdsToQuery == null || ticketIdsToQuery.isEmpty()) {
            return new List<CMPL123CME__Complaint__c>();
        }
        return [SELECT Id, Name, Ticket_Type__c, Overall_Reportable_Status__c,
            Is_Custom_response_child_created__c, Customer_Reply_Required__c,
            (SELECT Id, Name, CMPL123_WF_Status__c FROM CMPL123CME__Questionnaires__r 
            WHERE CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Voided),
            (SELECT Id, Name, CMPL123_WF_Status__c FROM CMPL123CME__Investigations__r 
            WHERE CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Voided),
            (SELECT Id, Name, Ticket_Review__r.Status__c FROM Ticket_Searches__r)
            FROM CMPL123CME__Complaint__c
            WHERE Id IN: ticketIdsToQuery
        ];
    }

    public static Map<String, Boolean> getFlagMapForTicket(CMPL123CME__Complaint__c ticketRecord) {     
        Boolean isReplyRequired       = ticketRecord.Customer_Reply_Required__c;
        Boolean hasMedEval            = ticketRecord.CMPL123CME__Questionnaires__r.size() > 0;  // questionnaire is medEval
        Boolean hasProdEval           = ticketRecord.CMPL123CME__Investigations__r.size() > 0;  // investigation is prodEval
        Boolean isInquiry             = ticketRecord.Ticket_Type__c == AspenConstants.STR_Inquiry;         
        Boolean hasTicketSearch       = ticketRecord.Ticket_Searches__r.size() > 0;        
        // 30-JAN-2023 Larry: Now calculates hasActiveTicketSearch
        Boolean hasActiveTicketSearch = false;
        for (Ticket_Search_Result__c searchRec : ticketRecord.Ticket_Searches__r) {
            if (searchRec.Ticket_Review__r.Status__c == AspenConstants.TICKSEARCH_STATUS_ACTIVE) {
                hasActiveTicketSearch = true;
                break;
            }
        }

        return new Map<String, Boolean> {
            AspenConstants.TICKETFLAG_IS_REPLY_REQUIRED        => isReplyRequired,
            AspenConstants.TICKETFLAG_HAS_PRODEVAL             => hasProdEval,
            AspenConstants.TICKETFLAG_HAS_MEDEVAL              => hasMedEval,
            AspenConstants.TICKETFLAG_IS_INQUIRY               => isInquiry,
            AspenConstants.TICKETFLAG_HAS_TICKET_SEARCH        => hasTicketSearch,
            AspenConstants.TICKETFLAG_HAS_ACTIVE_TICKET_SEARCH => hasActiveTicketSearch           
        };
    }
    public class MDCRequest {
    public String mdcTriggerName;
    public Map<Id, SObject> newMap;
    public String relatedTicketIdAPI;
    public String relatedTicketNumberAPI;
    public String auditEntryField;
    public Boolean createJunctionRecord;

    public MDCRequest(
        String mdcTriggerName,
        Map<Id, SObject> newMap,
        String relatedTicketIdAPI,
        String relatedTicketNumberAPI,
        String auditEntryField,
        Boolean createJunctionRecord
    ) {
        this.mdcTriggerName = mdcTriggerName;
        this.newMap = newMap;
        this.relatedTicketIdAPI = relatedTicketIdAPI;
        this.relatedTicketNumberAPI = relatedTicketNumberAPI;
        this.auditEntryField = auditEntryField;
        this.createJunctionRecord = createJunctionRecord;
    }
}
}