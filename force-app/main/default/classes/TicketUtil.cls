/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
 * @What  : TicketUtil
 * @Why   : Handles  Different scenarios from Translation Task Trigger.
 * @When  : 07-AUG-2018
 * @Where : From ADDInvestigationHandlerclass, ADDMedEvalTaskTriggerHandler class, ADDS4RiskManagementTriggerHandler class, ADDS4TranslationTaskTiggerHandler class, ADDTranslations class,
            ADDUpdateTicketStatus, ADDUtil, AttachmnetsWithMedEvalMDCLogic,  AttachmnetsWithProdEvalMDCLogic, AttachmnetsWithTicketSearchMDCLogic, ComplaintTriggerHandler,
            CustomerResponseCustExpectMDCCustom, CustomerResponseTriggerHandler, EvaluationHandlerTemp, InternalTicketServiceProcessor, PTWithMedEvalLikelyCauseMDCCustom,
            QuestionnaireItemsTriggerHandler, QuestionnaireTriggerHandler, TicketServiceHandler, TicketUtil,  TranslationTaskWithINQProdEvalMDCCustom, TranslationTaskWithOpenProdEvalMDCCustom,
            TranslationTaskWithProdEvalMDCCustom, TranslationTaskWithTckMedEvalMDCCustom, UpdateMedEvalDecisionTreeBatch, UpdateTicketSearchAdverseEvent class,
             CMPL123CME_Complaint_AuditTrigger, CMPL123CME_EMDR_AuditTrigger, CMPL123CME_Investigation_AuditTrigger, CMPL123CME_MEDDEV_AuditTrigger, Customer_Response_AuditTrigger,
            Customer_Response_Master_AuditTrigger, KI_Log_AuditTrigger, pRE_Question_AuditTrigger, Product_Lot_AuditTrigger, QuestionnaireItemsTrigger, Return_AuditTrigger trigger
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID       Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                    06-APR-2017            Work ID / Case ID     Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    04-06-2020             Code Audit            Removed 'System.debug()'.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                    15-06-2020             Code Audit            Formatting.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * OOber                    06-16-2020             Defect #101.1         Removed hardcoded emails
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             20-JUL-2023            CHaRM R3.1, no IDPR   Made a flag to test addTrace and sendLimits
 * without pressuring the servers. See https://help.salesforce.com/s/articleView?id=000384939&type=1
 * Also optimized validateRecordLockOnClosedStatus.
 * --------------------------------------------------------------------------------------------------------------------------------------
 **/
public class TicketUtil {
    // avoid recursive trigger
    private static Boolean firstRun = true;
    @testVisible private static Boolean isLimitEmailSent = false;
    // R3.1, Larry: Added this flag to test addTrace without taxing Salesforce's servers
    @testVisible private static Boolean isForceEmail = false;
    // R3.1, Larry: Changed from public to private since it is not and should not be used elsewhere
    private static List<String> txnList = new List<String>();
    // Note: This should NOT be public, but TicketServiceHandler accesses it directly...
    public static String ticketJsonBody = '';
    public static final Set<String> TICKET_LOCKED_STATUSES = new Set<String>{
        AspenConstants.STR_WF_Closed_Done,
        AspenConstants.STR_WF_Closed_Voided
    };

    /**
    * @Method       : isFirstRun
    * @Invoke       : From ADDS4TranslationTaskTiggerHandler class, ComplaintTriggerHandler class, TicketUtil class
    * @Description  : called to avoid recursion
    * @Return       : boolean
    * @Params       : N/A
    **/
    public static boolean isFirstRun(){
        if(firstRun){
            firstRun = false;
            return true;
        }else{
            return firstRun;
        }
    }

    /**
     * @Method       : closeTicketBasedOnConditions
     * @Invoke       : From ADDS4TranslationTaskTiggerHandler class, ComplaintTriggerHandler class, CustomerResponseTriggerHandler class, QuestionnaireTriggerHandler class,
                     TicketUtil class
     * @Description  : W-000108/W-000107 - Based on ticket "MDC All ACKs Received?"
     *                 And "CMSNext Status" field values close ticket.
     * @Return       : N/A
     * @Params       : Set<Id> setTicketIds
     **/
    public static void closeTicketBasedOnConditions(Set<Id> setTicketIds) {
        TicketUtil.addTrace('TicketUtil.closeTicketBasedOnConditions - ' + setTicketIds);
        List<CMPL123CME__Complaint__c> lstTicketsToClose = New List<CMPL123CME__Complaint__c>();
        // get all tickets related to current translation task which are open
        // 22MAR19 - DEF#285 - Fix for Registration Closed [Removed Ticket Type in the where clause]
        for(CMPL123CME__Complaint__c objTicket :
            [SELECT Id, CMSNext__c, MDC_All_ACKs_Received__c, CMPL123Task_Key_Value__c, Ticket_Type__c,
             Ready_to_Close__c, CMPL123CME__CMPL123_WF_Status__c, CMPL123CME__CMPL123_WF_Action__c,
             (SELECT Id FROM Translation_Tasks__r WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%') LIMIT 1),
             (SELECT Id FROM Customer_Responses__r WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%') LIMIT 1),
             (SELECT Id FROM CMPL123CME__Questionnaires__r WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%') LIMIT 1)
             FROM CMPL123CME__Complaint__c WHERE Id IN: setTicketIds AND CMSNext__c = 'Closed'
             AND MDC_All_ACKs_Received__c = true]){
            // 16MAR19 - DEF#285 - Fix for Registration Closed to Futher Review
            CMPL123CME__Complaint__c objTicketTemp = New CMPL123CME__Complaint__c(Id = objTicket.Id);
            // 28MAR19 - DEF#650 - Fix for Inquiry Closure from CMSNext
            if(objTicket.Translation_Tasks__r.size() == 0 && objTicket.Customer_Responses__r.size() == 0) {
                if(objTicket.Ticket_Type__c == 'Inquiry' && objTicket.CMPL123CME__CMPL123_WF_Status__c == 'Opened' && objTicket.CMPL123CME__CMPL123_WF_Action__c != 'Reopen' && objTicket.CMPL123CME__CMPL123_WF_Action__c != 'Reopen - Translation Required'){
                    objTicketTemp.CMPL123Task_Key_Value__c = 'closeInquiry';
                    lstTicketsToClose.add(objTicketTemp);
                } else if(objTicket.CMPL123CME__Questionnaires__r.size() == 0) {
                    if(objTicket.Ticket_Type__c == 'Service' && objTicket.CMPL123CME__CMPL123_WF_Status__c == 'Opened' && objTicket.CMPL123CME__CMPL123_WF_Action__c != 'Reopen' && objTicket.CMPL123CME__CMPL123_WF_Action__c != 'Reopen - Translation Required') {
                        objTicketTemp.CMPL123Task_Key_Value__c = 'closeService';
                        lstTicketsToClose.add(objTicketTemp);
                    } else if(objTicket.Ticket_Type__c == 'Complaint' && objTicket.CMPL123CME__CMPL123_WF_Status__c == 'Registration Closed' && objTicket.CMPL123CME__CMPL123_WF_Action__c != 'Reopen - Translation Required') {
                        objTicketTemp.CMPL123Task_Key_Value__c = 'complaintrcfr';
                        objTicketTemp.Ready_to_Close__c = '';
                        lstTicketsToClose.add(objTicketTemp);
                    }
                }
            }
        }

        if(lstTicketsToClose.size() > 0){
            update lstTicketsToClose;
        }
    }

    /**
    * @Method       : processAutomatedHistoryRecord
    * @Invooke      : From ADDDemoteToServiceHandler class, ADDInvestigationHandler class, ADDReviewFileTranslationController class, ADDS4RiskManagementTriggerHandler class,
                    ADDS4TranslationTaskTiggerHandler class, ADDS5TicketSearchResultController class, ADDUtil class, ComplaintTriggerHandler_Test class,
                    ComplaintTriggerHandler class, QuestionnaireTriggerHandler class, TicketFileTranslationController class, TicketTranslationController class,
                    TicketUtil class, TranslationEmailHandler class,
    * @Description  : W-000129 - Based in Parent Id, and workflow step generate workflow history record
    * @Return       : CMPL123__WF_History__c
    * @Params       : String strParentId, CMPL123__WF_Step__c objWFStep
    **/
    public static CMPL123__WF_History__c processAutomatedHistoryRecord(String strParentId, CMPL123__WF_Step__c objWFStep) {
        CMPL123__WF_History__c objWFHistoryAutoPromoted = New CMPL123__WF_History__c(
            CMPL123__Related_Id__c = strParentId,
            CMPL123__Workflow_Step__c = objWFStep.Id,
            CMPL123__Action__c = objWFStep.CMPL123__Action__r.Name,
            CMPL123__ESign_Applied__c = false, //objWFStep.CMPL123__Action__r.CMPL123__Is_ESign_Required__c,
            CMPL123__Comment__c = 'Applied through task update',
            CMPL123__Status__c = objWFStep.CMPL123__End_Status__r.Name,
            CMPL123__Change_Summary__c= 'Updated Status From '+objWFStep.CMPL123__Start_Status__r.Name+' to '+ objWFStep.CMPL123__End_Status__r.Name
        );
        return objWFHistoryAutoPromoted;
    }

    /**
    * @Method       : populateWFFields
    * @Description  : W-000129 - populate WF field values for the passed record
    * @Return       : sObject
    * @Params       : sObject objReference,String strWFStatus, String strWFAction
    **/
    public static sObject populateWFFields(sObject objReference,String strWFStatus, String strWFAction) {
        Id recordId = String.valueOf(objReference.get('Id'));
        String strObjectAPIName = recordId.getSObjectType().getDescribe().getName() == 'CMPL123CME__Complaint__c' ? 'CMPL123CME__' :'';
        objReference.put(strObjectAPIName+'CMPL123_WF_Status__c', strWFStatus);
        objReference.put(strObjectAPIName+'CMPL123_WF_Action__c', strWFAction);
        objReference.put(strObjectAPIName+'CMPL123_WF_Action_Performed_On__c', DateTime.now());
        objReference.put(strObjectAPIName+'CMPL123_WF_Action_Performed_By__c', Userinfo.getUserId());
        return objReference;
    }

    /**
     * Function to send the limit details to Admin for review
     * @revision R3.1, Larry: Added a deprecation message
     */
    public static void addTrace(String txn) {
        System.debug(LoggingLevel.FINER, 'Deprecated. This method was used for debugging before R1.0');
        Integer numQueries = Limits.getQueries();
        Integer cpuTime = Limits.getCpuTime();
        txnList.add(txn + '~' + numQueries + '~' + cpuTime);
        Boolean isLimitsHit = numQueries > 75 || cpuTime > 7500;
        // Adding a Static Variable to stop the too many email invocation
        if (isForceEmail || (isLimitsHit && !isLimitEmailSent)) {
            isLimitEmailSent = true;
            sendLimits(txn);
        }
    }

    /**
     * @Method       : sendLimits
     * @Invoke       : From InternalTicketServiceProcessor class, TicketUtil class, TicketServiceHandler class, QuestionnaireItemsTrigger trigger
     * @Description  : To handle all the logic in before insert event
     * @Return       : N/A
     * @Params       : N/A
     * @Revision     : R3.1, Larry: Added a deprecation message
     **/
    public static void sendLimits(String subjLine) {
        System.debug(LoggingLevel.FINER, 'Deprecated. This method was used for debugging before R1.0');
        //if(isLimitEmailSent) { return; }
        // Step 0: Create a master list to hold the emails we'll send
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        // Step 1: Create a new Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        // Step 2: Set list of people who should get the email
        List<String> sendTo = new List<String>();
        String dispName = '';
        if(!UserInfo.getOrganizationId().equalsIgnoreCase('00D0j0000000PKMEA2')) { // Integ org Id
            dispName = 'CHaRM DevIQ';
        } else {
            dispName = 'CHaRM Services';
        }

        mail.setToAddresses(sendTo);

        // Step 3: Set who the email is sent from
        mail.setSenderDisplayName(dispName);

        // Step 4. Set email contents - you can use variables!
        mail.setSubject('Limit on ' + subjLine + ' by ' + UserInfo.getName());

        String body = 'Txn Flow details are mentioned below';
        for(String txnStr: txnList) {
            body += '<br/>' + txnStr;
        }

        // Limit Details
        body += '<br/><br/> Limit Details for the above txns are listed below';
        body += '<br/>CPU Time: ' + Limits.getCpuTime() + ' of ' + Limits.getLimitCpuTime();
        body += '<br/>SOQL: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries();
        body += '<br/>DML: ' + Limits.getDMLStatements() + ' of ' + Limits.getLimitDMLStatements();
        body += '<br/><br/> Thanks';
        mail.setHtmlBody(body);

        // Include Attachment
        if(String.isNotBlank(ticketJsonBody)) {
            Blob b = Blob.valueOf(ticketJsonBody);

            // Create the email attachment
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName('ticketJson.txt');
            efa.setBody(b);

            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
            ticketJsonBody = '';
        }

        // Step 5. Add your email to the master list
        mails.add(mail);
        if(sendTo.size() > 0)
            Messaging.sendEmail(mails);

        isLimitEmailSent = true;
    }

    /**
     * @Method       : Fields in Closed - Voided and Closed - Done statuses should be locked except CMSNext Status field to support reopen automation.
     * @Invoke       : from ComplaintTrigger Handler class
     * @Description  : Gets the new Complaints and old complaints, and validates update functionality for Record edit on Closed status.
     * @Return       : N/A
     * @Params       : List<CMPL123CME__Complaint__c> newComplaintList, Map<Id,CMPL123CME__Complaint__c> oldComplaintMap
     * @Revision     : R3.1, Larry: Reorganized logic to greatly cut down on CPU time.
     * Average runtime went from 80ms down to 30ms or less. Extensive testing was
     * included in TicketUtilTest; the only logical difference after these changes
     * is that the function no longer crashes if oldComplaintMap is null.
     **/
    public static void validateRecordLockOnClosedStatus(List<CMPL123CME__Complaint__c> newComplaintList, Map<Id,CMPL123CME__Complaint__c> oldComplaintMap){
        // R3.1, Larry: Now checks against WorkFlow Status before doing anything else.
        List<CMPL123CME__Complaint__c> lockedTickets = new List<CMPL123CME__Complaint__c>();
        for(CMPL123CME__Complaint__c ticketNew : newComplaintList){
            CMPL123CME__Complaint__c ticketOld = oldComplaintMap?.get(ticketNew.Id);
            if (ticketNew.CMPL123CME__CMPL123_WF_Status__c == ticketOld?.CMPL123CME__CMPL123_WF_Status__c &&
                TICKET_LOCKED_STATUSES.contains(ticketNew.CMPL123CME__CMPL123_WF_Status__c)
            ) {
                lockedTickets.add(ticketNew);
            }
        }

        // Abort early to avoid checking nearly every Ticket field.
        // Also covers the cases where oldComplaintMap == null or oldComplaintMap.isEmpty().
        if (lockedTickets.isEmpty()) {
            return;
        }

        Set<String> fieldsToBeChecked = new Set<String>();
        Set<String> fieldSet = new Set<String>();

        //Get the custom fields from the custom metadata
        for(Schema.FieldSetMember fld : SObjectType.CMPL123CME__Complaint__c.FieldSets.Fields_editable_on_Closed_Complaint.getFields()){
            fieldSet.add(fld.getFieldPath().toLowerCase());
        }

        for(String fldName : CMPL123CME__Complaint__c.SObjectType.getDescribe().fields.getMap().keySet()){
            if(fldName.containsIgnoreCase('__c') && !fieldSet.contains(fldName.toLowerCase())){
               fieldsToBeChecked.add(fldName);
            }
        }

        for(CMPL123CME__Complaint__c objComplaint : lockedTickets){
            for(String fldName : fieldsToBeChecked){
                CMPL123CME__Complaint__c oldTicket = oldComplaintMap.get(objComplaint.Id);
                if (objComplaint.get(fldName) != oldTicket.get(fldName)) {
                   System.debug(LoggingLevel.FINE, 'FIELD NAME ' + fldName);
                   objComplaint.addError(System.Label.Complaint_Record_Locked);
                }
            }
        }
    }

}