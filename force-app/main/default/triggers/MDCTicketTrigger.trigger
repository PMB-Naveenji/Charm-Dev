/**
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : MDCTicketTrigger
* @Why   : To Handles all the customization involved on CMPL123__MDC_Ticket__c object.
* @When  : 07-FEB-2019
* @Where : From CMPL123__MDC_Ticket__c object Events
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
*  Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
*  Admin                   07-FEB-2019             Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
*  DSkak                   28-DEC-2020             TWD Upgrade issue    Added 'before insert', 'before update' events to trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
*  RSlob                   28-DEC-2020             TWD Upgrade          Commented unnecessary logging.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger MDCTicketTrigger on CMPL123__MDC_Ticket__c (before insert, before update, after insert, after update, after delete) {
    public static boolean runMDCOnceFlag = false;
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        //TicketUtil.addTrace('MDCTicketTrigger. Insert = ' + Trigger.isInsert + '. Update = ' + Trigger.isUpdate + '. Delete = ' + Trigger.isDelete);
        if(!runMDCOnceFlag) {
            runMDCOnceFlag = Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) ? false : true;
            new ADDMDCTicketTriggerhandler().run();
        }
    }
}