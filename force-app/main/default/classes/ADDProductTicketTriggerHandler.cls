/*
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : ADDProductTicketTriggerHandler.
 * @Why   : Handles all the customization involved on Product Ticket object.
 * @When  : 06-APR-2017.
 * @Where : From ComplaintTriggerHandler class, Product_Ticket_AuditTrigger Trigger.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID               Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                    06-APR-2017            Work ID / Case ID             Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    04-JUN-2020            Code Audit                    Removed 'System.debug()'.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                    15-JUN-2020            Code Audit                    Formatting.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    28-DEC-2020            TWD Upgrade issue             Added 'executeLogicFromWFRules()' method to move
 *                                                                                  logic from Workflow Rules with Field Updates
 *                                                                                  on Product-Ticket to Apex.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DCoffey                  11-FEB-2021            Fix defect #157 Issues        Added createMDCTicket method. Calling from After Insert
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             31-AUG-2022            CHaRM R2.2, IPDR 66           Added methods fixTicketFieldsAfterInsert, fixTicketFieldsAfterUpdate,
 * fixProdEvalFields, getIsProdEvalNeedsUpdated, getCumulativeProdEvalFields, fixProdEvalFieldsDoUpdate. Added inner class ProdEvalFieldsWrap
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             21-NOV-2022            CHaRM R2.2.1, IPDR 66         Comment adjustments
 */

public class ADDProductTicketTriggerHandler extends TriggerHandler {
    //Recursion Handler
    public static Boolean executeOnceAfterUpdate = false;
    public static Boolean newPTFlag = false;

    // added on : 19 FEB 2019 to handle future calls.
    public static Boolean futureHandlerOnlyOnce = false;

    @testVisible private static Integer prodEvalCumulNamesLen {
        get {
            if (prodEvalCumulNamesLen == null) {
                Map<String, SObjectField> fields =
                    SObjectType.CMPL123CME__Investigation__c.fields.getMap();
                prodEvalCumulNamesLen = fields.get('Products__c').getDescribe().getLength();
            }
            return prodEvalCumulNamesLen;
        }
        private set;
    }

    @testVisible private static Integer prodEvalCumulListNumsLen {
        get {
            if (prodEvalCumulListNumsLen == null) {
                Map<String, SObjectField> fields =
                    SObjectType.CMPL123CME__Investigation__c.fields.getMap();
                prodEvalCumulListNumsLen = fields.get('Product_List_Numbers__c').getDescribe().getLength();
            }
            return prodEvalCumulListNumsLen;
        }
        private set;
    }

    @testVisible private static Integer prodEvalCumulLotNumsLen {
        get {
            if (prodEvalCumulLotNumsLen == null) {
                Map<String, SObjectField> fields =
                    SObjectType.CMPL123CME__Investigation__c.fields.getMap();
                prodEvalCumulLotNumsLen = fields.get('Product_Lot_Numbers__c').getDescribe().getLength();
            }
            return prodEvalCumulLotNumsLen;
        }
        private set;
    }

    /*
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeInsert() {
        // TWD Upgrade issue - FIX START
        executeLogicFromWFRules();
        // TWD Upgrade issue - FIX END
    }

    /*
    * @Method       : afterInsert
    * @Invoke       : Events from TriggerHandler after insert
    * @Description  : To handle all the logic in after insert event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void afterInsert() {
        newPTFlag = true;
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();

        // 12-SEP-2022 Larry: Moved logic into a dedicated function
        fixTicketFieldsAfterInsert((List<Product_Ticket__c>) Trigger.new);
        // 12-SEP-2022 Larry: Added this function call
        fixProdEvalFields(null, (Map<Id, Product_Ticket__c>) Trigger.newMap);
    }

    /*
    * @Method       : beforeUpdate
    * @Invoke       : Events from TriggerHandler before update
    * @Description  : To handle all the logic in before update event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeUpdate() {
        // TWD Upgrade issue - FIX START
        executeLogicFromWFRules();
        // TWD Upgrade issue - FIX END

        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : afterUpdate
    * @Invoke       : Events from TriggerHandler after update
    * @Description  : To handle all the logic in after update event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void afterUpdate() {
        if(!executeOnceAfterUpdate){
            //code which invokes 123Compliance platform audit and workflow code
            CMPL123.AuditHandler.handleAudit();
            //executeOnceAfterUpdate = true;
        }

        // 12-SEP-2022 Larry: Moved logic into a dedicated function
        fixTicketFieldsAfterUpdate((Map<Id, Product_Ticket__c>) Trigger.oldMap,
            (List<Product_Ticket__c>) Trigger.new);
        // 12-SEP-2022 Larry: Added this function call
        fixProdEvalFields((Map<Id, Product_Ticket__c>) Trigger.oldMap,
            (Map<Id, Product_Ticket__c>) Trigger.newMap);
    }

    /**
     * @Invoke       : Events from TriggerHandler after insert
     * @Description  : Updates cumulative Ticket fields
     * @Return       : Product-Tickets whose Tickets will be updated. Can be empty, but never null
     * @Params       : newRecords is Trigger.new
     * @Revision     : 12-SEP-2022 Larry: Moved all code in this function out of afterInsert
     */
    private static Set<Id> fixTicketFieldsAfterInsert(List<Product_Ticket__c> newRecords) {
        Set<Id> productTicketIds = new Set<Id>();
        for (Product_Ticket__c pt : newRecords) {
            if (pt.Product_Family_Static__c != null ||
                pt.Product_List_Number__c  != null ||
                pt.Batch_Lot_Serial__c != null ||
                pt.Likely_Cause__c != null ||
                pt.Product_Name__c != null
            ) {
                productTicketIds.add(pt.Id);
            }
        }
        // added on : 19 FEB 2019 to handle future calls.
        if (productTicketIds.size() > 0 ) {//&& futureHandlerOnlyOnce == false
            ADDTicketUpdateAsync.ticketUpdateAsync(productTicketIds, true);
        }
        return productTicketIds;
    }

    /**
     * @Invoke       : Events from TriggerHandler after update
     * @Description  : Updates cumulative Ticket fields
     * @Return       : Product-Tickets whose Tickets will be updated. Can be empty, but never null
     * @Params       : oldMap is Trigger.oldMap
     *                 newRecords is Trigger.new
     * @Revision     : 12-SEP-2022 Larry: Moved all code in this function out of afterUpdate
     */
    private static Set<Id> fixTicketFieldsAfterUpdate(Map<Id, Product_Ticket__c> oldMap,
        List<Product_Ticket__c> newRecords
    ) {
        Set<Id> productTicketIds = new Set<Id>();
        for (Product_Ticket__c pt : newRecords) {
            Product_Ticket__c oldPt = oldMap.get(pt.Id);

            if (pt.Product_Family_Static__c != oldPt.Product_Family_Static__c ||
                pt.Product_List_Number__c != oldPt.Product_List_Number__c ||
                pt.Batch_Lot_Serial__c != oldPt.Batch_Lot_Serial__c ||
                pt.Likely_Cause__c != oldPt.Likely_Cause__c ||
                pt.Product_Name__c != oldPt.Product_Name__c
            ) {
                productTicketIds.add(pt.Id);
            }
        }
        // added on : 19 FEB 2019 to handle future calls.
        if (productTicketIds.size() > 0 ) {//&& futureHandlerOnlyOnce == false
            ADDTicketUpdateAsync.ticketUpdateAsync(productTicketIds, false);
        }
        return productTicketIds;
    }

    /*
    * @Method       : beforeDelete
    * @Invoke       : Events from TriggerHandler before delete
    * @Description  : To handle all the logic in before delete event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : afterDelete
    * @Invoke       : Events from TriggerHandler after delete
    * @Description  : To handle all the logic in after delete event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void afterDelete() {
    }

    /*
    * @Method       : executeLogicFromWFRules
    * @Description  : TWD Upgrade issue - this method contains logic from Workflow Rules with Field Updates on Product-Ticket.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void executeLogicFromWFRules() {
        List<Product_Ticket__c> newList = (List<Product_Ticket__c>) Trigger.new;
        Map<Id, Product_Ticket__c> oldMap = (Map<Id, Product_Ticket__c>) Trigger.oldMap;

        Set<Id> complaintIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();

        for (Product_Ticket__c newPT :newList) {
            if (null != newPT.Event_Ticket__c) {
                complaintIds.add(newPT.Event_Ticket__c);
            }

            if (null != newPT.Product__c) {
                productIds.add(newPT.Product__c);
            }
        }

        Map<Id, CMPL123CME__Complaint__c> complaints = new Map<Id, CMPL123CME__Complaint__c>([
            SELECT Id, RecordType.DeveloperName, CMSNext_Ticket_Number__c, Service_Type__c, Trending_issue_Bucket__c
            FROM CMPL123CME__Complaint__c
            WHERE Id IN :complaintIds
        ]);

        Map<Id, CMPL123__Product__c> products = new Map<Id, CMPL123__Product__c>([
            SELECT Id, List_Base__c, List_Number__c
            FROM CMPL123__Product__c
            WHERE Id IN :productIds
        ]);

        for (Product_Ticket__c newPT :newList) {
            //  Update Product List Number
            if (null != newPT.Product__c) {
                newPT.Product_List_Number_Text__c = products.get(newPT.Product__c).List_Number__c;
                newPT.List_Base_Trending_Issue_Bucket__c = products.get(newPT.Product__c).List_Base__c
                    + '/'
                    + (null != newPT.Event_Ticket__c
                        ? complaints.get(newPT.Event_Ticket__c).Trending_issue_Bucket__c
                        : '');
            }

            if (!Trigger.isInsert) {
                continue;
            }

            //  Autoset Registration Number
            if (null != newPT.Ticket_Number__c) {
                String parentRecordType = complaints.get(newPT.Event_Ticket__c).RecordType.DeveloperName;

                newPT.Registration_Number__c = complaints.get(newPT.Event_Ticket__c).CMSNext_Ticket_Number__c
                + '('
                + (parentRecordType == AspenConstants.STR_Service
                    ? complaints.get(newPT.Event_Ticket__c).Service_Type__c + ' '
                    : '')
                + parentRecordType
                + ')';
            }

            //  Concatenate Batch lot number, likely cause and List number field values.
            if (null != newPT.Product_Name__c || null != newPT.Product_List_Number__c || null != newPT.Batch_Lot_Serial__c || null != newPT.Likely_Cause__c) {
                newPT.Bactch_Likely_List__c = newPT.Product_Name__c + ' - -' + newPT.Product_List_Number__c + ' - ' + newPT.Batch_Lot_Serial__c + '\n'
                    + 'Likely Cause: ' + newPT.Likely_Cause__c;
            }
        }
    }

    /**
     * Wrapper class that composes cumulative fields for ProdEvals.
     * 
     * To understand what a "cumulative field" is, be aware that
     * One Ticket can have many child ProdEvals. Also,
     * One Ticket can have many child Product-Tickets.
     * ProdEvals and Product-Tickets are NOT directly related by lookup fields,
     * so ProdEvals cannot show Product-Ticket field values with a dot operator.
     * From a ProdEval list view, Users want to see field values from all
     * Product-Tickets under the same parent Ticket shared by a ProdEval.
     * Such text fields must be composed with automation.
     * 
     * For example, say we have a Ticket with 2 Product-Tickets and 1 ProdEval.
     * It has a Product-Ticket child with ProductName__c = "Foo". Also,
     * It has a Product-Ticket child with ProductName__c = "Bar".
     * Then the ProdEval's CumulativeProductNames__c = "Foo,Bar"
     * @Author       : Larry Resnik
     * @Date         : 29-JUL-2022
     * @Revision     : 21-NOV-2022 Larry: Rewrote this docstring's description
     * so that "cumulative field" is explained within the codebase.
     */
    public class ProdEvalFieldsWrap {
        // setter is private to ensure these Lists will always be non-null
        List<String> lotNums {get;private set;}
        List<String> listNums {get;private set;}
        List<String> productNames {get;private set;}

        public ProdEvalFieldsWrap() {
            lotNums = new List<String>();
            listNums = new List<String>();
            productNames = new List<String>();
        }

        public void addFields(Product_Ticket__c pt) {
            if (!String.isBlank(pt.Batch_Lot_Serial__c)) {
                // Not a formula!
                lotNums.add(pt.Batch_Lot_Serial__c);
            }
            if (!String.isBlank(pt.Product_List_Number__c)) {
                // Formula is Product__r.List_Number__c
                listNums.add(pt.Product_List_Number__c);
            }
            if (!String.isBlank(pt.Product_Name__c)) {
                // Formula is Product__r.Name
                productNames.add(pt.Product_Name__c);
            }
        }

        public String getCumulativeLotNums() {
            String ret = String.join(lotNums, ',');
            if (ret.length() > prodEvalCumulLotNumsLen) {
                ret = System.label.CumulativeFieldTooLong;
            }
            return ret;
        }

        public String getCumulativeListNums() {
            String ret = String.join(listNums, ',');
            if (ret.length() > prodEvalCumulListNumsLen) {
                ret = System.label.CumulativeFieldTooLong;
            }
            return ret;
        }

        public String getCumulativeProductNames() {
            String ret = String.join(productNames, ',');
            if (ret.length() > prodEvalCumulNamesLen) {
                ret = System.label.CumulativeFieldTooLong;
            }
            return ret;
        }
    }

    /**
     * Updates cumulative ProdEval fields caused by changes in triggered Product-Tickets
     * 
     * Specifically, changes on a Product-Ticket's Likely Cause, Batch/Lot/Serial Number,
     * or Product lookup can cause this
     * @param oldMap Same as Trigger.oldMap. Can be null
     * @param newMap Same as Trigger.newMap. Can be null
     * @return All ProdEvals which were updated. Can be empty, but never null
     * @author Larry Resnik, 13-SEP-2022
     */
    public static List<CMPL123CME__Investigation__c> fixProdEvalFields(
        Map<Id, Product_Ticket__c> oldMap, Map<Id, Product_Ticket__c> newMap
    ) {
        newMap = newMap != null ? newMap : new Map<Id, Product_Ticket__c>();
        Map<Id, List<Product_Ticket__c>> ticketIdToAllRecentPt = new Map<Id, List<Product_Ticket__c>>();
        // Determine which Tickets need to update child ProdEvals from triggered Product-Tickets
        Map<Id, CMPL123CME__Complaint__c> changedTicketIdToRec = new Map<Id, CMPL123CME__Complaint__c>();

        for (Id ptId : newMap.keySet()) {
            Product_Ticket__c ptNew = newMap.get(ptId);
            Product_Ticket__c ptOld = oldMap?.get(ptId);
            if (getIsProdEvalNeedsUpdated(ptNew, ptOld)) {
                changedTicketIdToRec.put(ptNew.Event_Ticket__c, null);
            }
        }

        return fixProdEvalFieldsDoUpdate(changedTicketIdToRec, newMap);
    }

    /**
     * States if a given Product-Ticket needs to update its sibling ProdEval(s)
     * @param ptNew One record from Trigger.new
     * @param ptOld The record from Trigger.old or oldMap with the same Id as ptNew
     * @return True if the ProdEval(s) need updated. False otherwise
     * @author Larry Resnik, 13-SEP-2022
     */
    @testVisible
    private static Boolean getIsProdEvalNeedsUpdated(Product_Ticket__c ptNew, Product_Ticket__c ptOld) {
        if (ptOld == null) {
            // Implies Trigger.isInsert is true, so this Product-Ticket must be put on the ProdEval
            return true;
        }

        // Check what lookup fields changed
        Boolean isProductChanged = ptNew.Product__c != ptOld.Product__c;

        // Check what non-formula fields changed
        // ProdEval fields use Product-Tickets such that Likely Cause = true
        Boolean isLikelyCauseChanged = ptNew.Likely_Cause__c != ptOld.Likely_Cause__c;
        // When set, Delete_Flag__c means it was deleted from CMSNext. Pretend it is deleted in Salesforce
        Boolean isDeleteFlagChanged = ptNew.Delete_Flag__c != ptOld.Delete_Flag__c;
        // Batch_Lot_Serial__c is subsequently used by the Product/Lot formula field Product_Lot_Number__c
        Boolean isLotNumChanged = ptNew.Batch_Lot_Serial__c != ptOld.Batch_Lot_Serial__c;

        // Check what formula fields changed
        // Formula is Product__r.List_Number__c; Used by Product/Lot formula Product_List_Number__c
        Boolean isListNumChanged = ptNew.Product_List_Number__c != ptOld.Product_List_Number__c;
        // Formula is Product__r.Name; Used by Product/Lot formula ProductName__c (not Product_Name__c)
        Boolean isProductNameChanged = ptNew.Product_Name__c != ptOld.Product_Name__c;

        // If any change happened, the ProdEval siblings must be updated
        return isProductChanged || isDeleteFlagChanged || isListNumChanged ||
            isProductNameChanged || isLotNumChanged || isLikelyCauseChanged;
    }

    /**
     * Composes cumulative ProdEval fields to be assigned onto a ProdEval record
     * @param queriedPtList All Product-Tickets related to ONE Ticket
     * @param triggeredNewMap Same as Trigger.newMap
     * @return An inner class that stores the fully composed cumulative ProdEval fields
     * @author Larry Resnik, 13-SEP-2022
     */
    @testVisible
    private static ProdEvalFieldsWrap getCumulativeProdEvalFields(
        List<Product_Ticket__c> queriedPtList, Map<Id, Product_Ticket__c> triggeredNewMap
    ) {
        ProdEvalFieldsWrap fields = new ProdEvalFieldsWrap();
        for (Product_Ticket__c queriedPt : queriedPtList) {
            // Use the triggered Product-Ticket because its data is the most up-to-date.
            // Use the queried Product-Ticket if the data was not changed (therefore not triggered)
            Product_Ticket__c triggeredPt = triggeredNewMap.get(queriedPt.Id);
            Product_Ticket__c toUsePt = triggeredPt != null ? triggeredPt : queriedPt;

            if (toUsePt != null &&
                toUsePt.Likely_Cause__c == AspenConstants.STR_Yes &&
                !toUsePt.Delete_Flag__c &&
                toUsePt.Product__c != null
            ) {
                fields.addFields(toUsePt);
            }
        }

        return fields;
    }

    /**
     * Updates cumulative fields on ProdEvals that point to the passed Tickets
     * @param changedTicketIdToRec Tickets affected by triggered Product-Tickets
     * @param triggeredNewMap Same as Trigger.newMap
     * @return All ProdEvals which were updated. Can be empty, but never null
     * @author Larry Resnik, 13-SEP-2022
     * @revision 21-NOV-2022 Larry: Was public so that a batch class could
     * access it. Changed to private
     */
    private static List<CMPL123CME__Investigation__c> fixProdEvalFieldsDoUpdate(
        Map<Id, CMPL123CME__Complaint__c> changedTicketIdToRec,
        Map<Id, Product_Ticket__c> triggeredNewMap
    ) {
        Map<Id, CMPL123CME__Investigation__c> toUpdate =
            new Map<Id, CMPL123CME__Investigation__c>();
        if (changedTicketIdToRec.isEmpty()) {
            return toUpdate.values();
        }

        final Set<String> OPEN_STATUSES = new Set<String>(
            AspenConstants.OPEN_WF_STATUSES_PRODEVAL.get(true)
        );
        // Get all ProdEvals and Product-Tickets under the same Ticket.
        // ProdEvals fill their cumulative fields only from Product-Tickets with the same parent Ticket
        for (CMPL123CME__Complaint__c ticket : [
            SELECT Id,
            // Just need Ids to update ProdEval fields
            (
                SELECT Id,
                CMPL123_WF_Status__c
                FROM CMPL123CME__Investigations__r
                WHERE CMPL123_WF_Status__c IN :OPEN_STATUSES
            ),
            // The purpose of these Product-Tickets fields can be checked in ProdEvalFieldsWrap
            (
                SELECT Id,
                Batch_Lot_Serial__c,
                Product_List_Number__c,
                Product_Name__c,
                // Need to query these fields in case they are accessed in getCumulativeProdEvalFields
                Likely_Cause__c,
                Delete_Flag__c,
                Product__c
                FROM Products_Events__r
                WHERE Likely_Cause__c = :AspenConstants.STR_Yes
                AND Delete_Flag__c = false
                AND Product__c != null
            )
            FROM CMPL123CME__Complaint__c
            WHERE Id IN :changedTicketIdToRec.keySet()
            WITH SECURITY_ENFORCED
        ]) {
            // Compose cumulative fields. The values are identical across sibling ProdEvals
            ProdEvalFieldsWrap fields = getCumulativeProdEvalFields(
                ticket.Products_Events__r, triggeredNewMap);
            // Fix the cumulative fields on each ProdEval under this Ticket
            for (CMPL123CME__Investigation__c prodEval : ticket.CMPL123CME__Investigations__r) {
                toUpdate.put(prodEval.Id,
                    new CMPL123CME__Investigation__c(
                        Id = prodEval.Id,
                        Product_Lot_Numbers__c = fields.getCumulativeLotNums(),
                        Product_List_Numbers__c = fields.getCumulativeListNums(),
                        Products__c = fields.getCumulativeProductNames(),
                        Has_Product_Lot_Child__c = !ticket.Products_Events__r.isEmpty()
                    )
                );
            }
        }

        List<CMPL123CME__Investigation__c> updatedProdEvals =
            new List<CMPL123CME__Investigation__c>();
        if (toUpdate.isEmpty()) {
            // There are no cumulative fields to update, so abort early
            return updatedProdEvals;
        }

        // Finally, save the changes
        {
            // Some of the ProdEvals might be closed, so do allOrNothing=false to
            // avoid a crash when trying to change them
            String allErrors = '';
            for (Database.SaveResult sr : Database.update(toUpdate.values(), false)) {
                if (sr.isSuccess()) {
                    updatedProdEvals.add(toUpdate.get(sr.getId()));
                } else {
                    for (Database.Error err : sr.getErrors()) {
                        allErrors += err.getStatusCode() + ': ' + err.getMessage() + ' \n';
                    }
                }
            }
            if (!String.isBlank(allErrors)) {
                // Throw combined errors so that it can be handled by the caller
                throw new DmlException(allErrors);
            }
        }
        return updatedProdEvals;
    }
}