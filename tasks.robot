*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    5x    1s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    ${site_url}=    Get Secret    robotsparebin
    Open Available Browser    ${site_url}[url]
    # Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Input from Dialog
    Add heading    Where can I find the order file?
    Add text input    file_url    label=URL
    ${response}=    Run dialog
    RETURN    ${response.file_url}

Get orders
    ${file_url}=    Input from Dialog
    # Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    Download    ${file_url}    overwrite=True
    ${orders}=    Read table from CSV    path=orders.csv    header=True
    RETURN    ${orders}

Close the annoying modal
    Click Button When Visible    //button[@class="btn btn-danger"]

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    //form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    Wait Until Page Contains Element    id:receipt

Go to order another robot
    Click Button    order-another

Store the receipt as a PDF file
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts${/}order_no_${order}.pdf
    RETURN    ${OUTPUT_DIR}${/}receipts${/}order_no_${order}.pdf

Take a screenshot of the robot
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}screenshots${/}robot_image_${order}.png
    RETURN    ${OUTPUT_DIR}${/}screenshots${/}robot_image_${order}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${robot_image}=    Create List    ${screenshot}:align=center
    Add Files To Pdf    ${robot_image}    ${pdf}    append=True
    Close Pdf    ${pdf}

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${zip_file_name}
