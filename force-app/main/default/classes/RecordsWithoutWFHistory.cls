/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : RecordsWithoutWFHistory.
* @Why   : Handles  the Records Without WFHistory.
* @When  : 29-JAN-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				29-JAN-2019		    Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                 15-06-2020          Code Audit                        Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 20-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 07-SEP-2020         Code Audit                        Added 'escapeSingleQuotes()' method call.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class RecordsWithoutWFHistory {
    String ObjApiName;

    @TestVisible
    List<sObject> lstRec = new List<sObject>();

    /*
    * @Method       : RecordsWithoutWFHistory constructor.
    * @Invoke       : N/A.
    * @Description  : To handle all the logic in before insert event.
    * @Return       : N/A.
    * @Params       : String ObjApiName.
    */
    public RecordsWithoutWFHistory(String ObjApiName) {
        this.ObjApiName = ObjApiName;
        processRecords();
    }

    /*
    * @Method       : processRecords constructor.
    * @Invoke       : N/A.
    * @Description  : To process records without WFHistory.
    * @Return       : N/A.
    * @Params       : String ObjApiName.
    */
    public void processRecords() {
        String userName = Label.Migration_User_Name;
        System.debug('User name : '+userName);

        Id userId = [SELECT Id FROM User WHERE Username = :userName].Id;

        Schema.sObjectType sObjType = Schema.getGlobalDescribe().get(ObjApiName);

        String keyPrfx = (sObjType.getDescribe().getKeyPrefix());

        System.debug('keyPrfx :'+keyPrfx);
        keyPrfx =+ keyPrfx+'%';

        Date DateRange = system.toDay().addDays(-60);

        Set<Id> setRelatedId = new Set<Id>();

        for (CMPL123__WF_History__c obj :[SELECT CMPL123__Related_Id__c
                                            FROM CMPL123__WF_History__c
                                            WHERE CMPL123__Related_Id__c LIKE :keyPrfx
                                                AND CreatedDate > :DateRange]) {
            setRelatedId.add(obj.CMPL123__Related_Id__c);
        }

        String query = 'SELECT Id, Name FROM ' + ObjApiName + ' WHERE Id NOT IN :setRelatedId AND CreatedDate > :DateRange AND CreatedById = :userId';

        lstRec = Database.query(String.escapeSingleQuotes(query));

        System.debug('lstRec: '+lstRec);
    }
}