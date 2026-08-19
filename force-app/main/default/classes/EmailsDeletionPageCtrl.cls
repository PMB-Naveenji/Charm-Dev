/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : EmailsDeletionPageCtrl
* @Why   : This class is used as controller for EmailsDeletionPage
* @When  : 02-JAN-2019
* @Where : From EmailsDeletionPage page
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:  
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                 Modification ID          Description
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    02-JAN-2020          Storage Limit            Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    13-JUL-2020          Code Audit               Added class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class EmailsDeletionPageCtrl {

    public Boolean isDeletionExecutionAttempted {get; set;}
    public String errorMessage {get; set;}
    public String deletionBatchJobId {get; set;}

    /*
    * @Method       : DeleteEmails
    * @Description  : To collect the records to pass to the execute method
    * @Invoke       : From EmailsDeletionPage page
    * @Return       : PageReference
    * @Params       : N/A
    */
    public PageReference DeleteEmails() {
        try {
            deletionBatchJobId = Database.executeBatch(new EmailsDeletionBatch(UserInfo.getUserId()), 50);
            errorMessage = null;
        } catch (Exception ex) {
            deletionBatchJobId = '';
            errorMessage = ex.getTypeName() + '; ' + ex.getMessage();
        } finally {
            isDeletionExecutionAttempted = true;
        }
        return null;
    }
}