<#
	Progress report:
 		There isn't much done at all. It's just a window with some text. Check back in two years or so and there might be something good.
#>

Add-Type -assembly System.Windows.Forms
$main_form = New-Object System.Windows.Forms.Form

# Set the title and size of the window:
$main_form.Text = "w11 nonadmin utils GUI"
$main_form.Width = 600
$main_form.Height = 400
$main_form.AutoSize = $true

# Set the form color:
$main_form.BackColor = "#000000"
$main_form.ForeColor = "#FFFFFF"

# Functions:
function TXT($text, $x, $y, $Style) { # Create text object
	$txt = New-Object system.Windows.Forms.Label
	$txt.Text = "$text"
	$txt.AutoSize = $true
	$txt.Font = New-Object System.Drawing.Font("arial",12,[System.Drawing.FontStyle]::$style)
	$txt.Location  = New-Object System.Drawing.Point($x,$y)
	$main_form.Controls.Add($txt)
}

# MAIN STUFF

TXT -text "!! NOT DONE YET !!" -x 0 -y 0 -style "Regular"

# Show form:
$main_form.ShowDialog()
exit 0
