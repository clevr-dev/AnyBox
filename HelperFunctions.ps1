function New-AnyBoxPrompt
{
	<#
	.SYNOPSIS
		Short description
	.DESCRIPTION
		Long description
	.PARAMETER Path
		Specifies a path to one or more locations.
	.PARAMETER LiteralPath
		Specifies a path to one or more locations. Unlike Path, the value of LiteralPath is used exactly as it
		is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose
		it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
		characters as escape sequences.
	.PARAMETER InputObject
		Specifies the object to be processed.  You can also pipe the objects to this command.
	.EXAMPLE
		C:\PS>
		Example of how to use this cmdlet
	.EXAMPLE
		$prompt = New-AnyBoxPrompt -
		Show-AnyB
	.INPUTS
		Inputs to this cmdlet (if any)
	.OUTPUTS
		Output from this cmdlet (if any)
	#>
	[cmdletbinding()]
	param(
		[AnyBox.InputType]$InputType = [AnyBox.InputType]::Text,
		[string]$Message,
		[string]$DefaultValue,
		[ValidateScript({$_ -gt 0})]
		[UInt16]$LineHeight,
		[switch]$ReadOnly,
		[switch]$ValidateNotEmpty,
		[string[]]$ValidateSet,
		[System.Management.Automation.ScriptBlock]$ValidateScript
	)

	if ($InputType -ne [AnyBox.InputType]::Text)
	{
		if ($InputType -eq [AnyBox.InputType]::None) {
			return($null)
		}

		if ($LineHeight -gt 1) {
			Write-Warning "'-LineHeight' parameter is only valid with text input."
		}

		if ($InputType -eq [AnyBox.InputType]::Checkbox) {
			if (-not $Message) {
				Write-Warning "Checkbox input requires a message."
				$Message = 'Message'
			}
		}
		elseif ($InputType -eq [AnyBox.InputType]::Password) {
			if ($DefaultValue) {
				Write-Warning 'Password input does not accept a default value.'
				$DefaultValue = $null
			}
		}
	}
	
	$p = New-Object AnyBox.Prompt

	$p.InputType = $InputType
	$p.Message = $Message
	$p.DefaultValue = $DefaultValue
	$p.LineHeight = $LineHeight
	$p.ValidateNotEmpty = $ValidateNotEmpty -as [bool]
	$p.ValidateSet = $ValidateSet
	$p.ValidateScript = $ValidateScript

	return($p)
}

function ConvertTo-Base64
{
	<#
	.SYNOPSIS
		Converts an image to its base64 string representation.
	.DESCRIPTION
		A base64 string can be passed to 'Show-Anybox' to show an image, which eliminates
		the reliance on the external file, making the script more easily portable.
	.PARAMETER ImagePath
		Specifies a path to one or more locations.
	.PARAMETER ImagePath
		Specifies a path to one or more locations.
	.EXAMPLE
		[string]$base64 = 'C:\Path\to\img.png' | ConvertTo-Base64
		Show-AnyBox -Image $base64 -Message 'Hello World'
	.INPUTS
		The path to an image file.
	.OUTPUTS
		The base64 string representation of the image at $ImagePath.
	#>
	param(
		[Parameter(ValueFromPipeline=$true)]
		[string[]]$ImagePath,
		[ValidateNotNullOrEmpty()]
		[System.Drawing.Imaging.ImageFormat]$ImageFormat = [System.Drawing.Imaging.ImageFormat]::Png
	)

	process {
		foreach ($img in $ImagePath) {
			$bmp = [System.Drawing.Bitmap]::FromFile($img)

			$memory = New-Object System.IO.MemoryStream
			$null = $bmp.Save($memory, $ImageFormat)

			[byte[]]$bytes = $memory.ToArray()

			$memory.Close()

			[System.Convert]::ToBase64String($bytes)
		}
	}
}

function ConvertTo-BitmapImage
{
	<#
	.SYNOPSIS
		Converts a base64 string to a BitmapImage object.
	.DESCRIPTION
		Used by 'Show-AnyBox' to convert a base64 string into a [System.Windows.Media.Imaging.BitmapImage].
	.PARAMETER base64
		The base64 string representing an image.
	.INPUTS
		The base64 string representing an image.
	.OUTPUTS
		A [System.Windows.Media.Imaging.BitmapImage] object.
	#>
	param([
		Parameter(ValueFromPipeline=$true)]
		[string[]]$base64
	)

	process {
		foreach($str in $base64) {
			$bmp = [System.Drawing.Bitmap]::FromStream((New-Object System.IO.MemoryStream (@(, [Convert]::FromBase64String($base64)))))

			$memory = New-Object System.IO.MemoryStream
			$null = $bmp.Save($memory, [System.Drawing.Imaging.ImageFormat]::Png)
			$memory.Position = 0

			$img = New-Object System.Windows.Media.Imaging.BitmapImage
			$img.BeginInit()
			$img.StreamSource = $memory
			$img.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
			$img.EndInit()
			$img.Freeze()

			$memory.Close()

			$img
		}
	}
}

function ConvertTo-Long
{
	<#
	.SYNOPSIS
		"Melts" object(s) into an array of key-value pairs.
	.DESCRIPTION
		Converts object(s) wide objects into a long array object for better display.
	.PARAMETER obj
		The object(s) to melt.
	.PARAMETER KeyName
		The name of the resulting key column; defaults to "Name".
	.PARAMETER obj
		The name of the resulting value column; defaults to "Value".
	.INPUTS
		One or more objects.
	.OUTPUTS
		An array of objects with properties "$KeyName" and "$ValueName".
	#>
	param(
		[Parameter(ValueFromPipeline=$true)]
		[object[]]$obj,
		[ValidateNotNullOrEmpty()]
		[string]$KeyName = 'Name',
		[ValidateNotNullOrEmpty()]
		[string]$ValueName = 'Value'
	)
	
	process {
		foreach ($o in $obj) {
			$o.psobject.Properties | foreach { [pscustomobject]@{ $KeyName = $_.Name; $ValueName = $_.Value } }
		}
	}
}