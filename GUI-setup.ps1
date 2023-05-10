# REWRITE OF SCRIPT WITH GUI WILL GO HERE
Add-Type -assembly System.Windows.Forms
$main_form = New-Object System.Windows.Forms.Form

# Set the title and size of the window:

$main_form.Text = "w11 nonadmin utils GUI"

$main_form.Width = 600

$main_form.Height = 400

$main_form.AutoSize = $true

# ADD STUFF HERE



# SHOW FORM

$main_form.ShowDialog()

exit 0
