/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketTranslationClosureController.
* @Why   : Translation items sent by vendor.
* @When  : 23-MAR-2017.
* @Where : From TicketTranslationClosure page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017            Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class TicketTranslationClosureController {

    public List<Translation_Item__c> translationItems{set;get;}

    /*
    * @Method       : TicketTranslationClosureController.
    * @Description  : Fetches all the translation items with native and translated text which is sent by vendor.
    * @Invoke       : From TicketTranslationClosure page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public TicketTranslationClosureController(){
        translationItems = new List<Translation_Item__c>();
        String recordIds = ApexPages.currentPage().getParameters().get('ids');
        if(recordIds != null){
            recordIds = recordIds.removeEnd(',');
            recordIds = recordIds.replaceAll('%2C',',');
            Set<String> ids = new Set<String>();
            ids.addAll(recordIds.split(','));
            for(Translation_Item__c t : [SELECT Id, Name, Field_Name__c, Native__c, Translated__c, Translation_Task__c,
                    Translation_Task__r.Name, Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c
                    FROM Translation_Item__c WHERE Translation_Task__c IN :ids AND Translation_Task__r.CMPL123_WF_Status__c = 'Translation Pending Review'
                    ORDER BY Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c]){

               if(t.Translated__c != null){
                    translationItems.add(t);
                }
            }
        }else{
            translationItems = new List<Translation_Item__c>();
        }
    }


    /*
    * @Method       : updateTranslations.
    * @Description  : To save translation items, before closing the translation task, user can review and update the text sent by vendor.
    *                   All the updated text gets saved into respective translation task and children.
    * @Invoke       : From TicketTranslationClosure page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void updateTranslations(){
        update translationItems;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,Label.Translation_Item_Update));
    }
}