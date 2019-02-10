# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

Describe "Send-MailMessage" -Tags CI {
    BeforeAll {
        #Register-PackageSource -Name nuget.org -Location https://www.nuget.org/api/v2 -ProviderName NuGet -Force

        $nugetPackage = "netDumbster"
        Find-Package $nugetPackage -ProviderName NuGet | Install-Package -Scope CurrentUser -Force

        $dll = "$(Split-Path (Get-Package $nugetPackage).Source)\lib\netstandard2.0\netDumbster.dll"
        Add-Type -Path $dll

        $server = [netDumbster.smtp.SimpleSmtpServer]::Start(25)

        function Read-Mail
        {
            param()
            return $server.ReceivedEmail[0]
        }
    }

    AfterEach {
        $server.ClearReceivedEmail()
    }

    AfterAll {
        $server.Stop()
    }

    $testCases = @(
        @{
            Name = "with mandatory parameters"
            InputObject = @{
                From = "user01@example.com"
                To = "user02@example.com"
                Subject = "Subject $(Get-Date)"
                Body = "Body $(Get-Date)"
                SmtpServer = "127.0.0.1"
            }
        }
        @{
            Name = "with ReplyTo"
            InputObject = @{
                From = "user01@example.com"
                To = "user02@example.com"
                ReplyTo = "noreply@example.com"
                Subject = "Subject $(Get-Date)"
                Body = "Body $(Get-Date)"
                SmtpServer = "127.0.0.1"
            }
        }
    )

    It "Can send mail message using named parameters <Name>" -TestCases $testCases {
        param($InputObject)

        Send-MailMessage @InputObject -ErrorAction SilentlyContinue

        $mail = Read-Mail

        $mail.FromAddress | Should -BeExactly $InputObject.From
        $mail.ToAddresses | Should -BeExactly $InputObject.To

        $mail.Headers["From"] | Should -BeExactly $InputObject.From
        $mail.Headers["To"] | Should -BeExactly $InputObject.To
        $mail.Headers["Reply-To"] | Should -BeExactly $InputObject.ReplyTo
        $mail.Headers["Subject"] | Should -BeExactly $InputObject.Subject

        $mail.MessageParts.Count | Should -BeExactly 1
        $mail.MessageParts[0].BodyData | Should -BeExactly $InputObject.Body
    }

    It "Can send mail message using pipline named parameters <Name>" -TestCases $testCases -Pending {
        param($InputObject)

        Set-TestInconclusive "As of right now the Send-MailMessage cmdlet does not support piping named parameters (see issue 7591)"

        [PsCustomObject]$InputObject | Send-MailMessage -ErrorAction SilentlyContinue

        $mail = Read-Mail

        $mail.FromAddress | Should -BeExactly $InputObject.From
        $mail.ToAddresses | Should -BeExactly $InputObject.To

        $mail.Headers["From"] | Should -BeExactly $InputObject.From
        $mail.Headers["To"] | Should -BeExactly $InputObject.To
        $mail.Headers["Reply-To"] | Should -BeExactly $InputObject.ReplyTo
        $mail.Headers["Subject"] | Should -BeExactly $InputObject.Subject

        $mail.MessageParts.Count | Should -BeExactly 1
        $mail.MessageParts[0].BodyData | Should -BeExactly $InputObject.Body
    }
}
