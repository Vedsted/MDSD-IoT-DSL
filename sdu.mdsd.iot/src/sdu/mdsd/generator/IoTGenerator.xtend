/*
 * generated by Xtext 2.20.0
 */
package sdu.mdsd.generator

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.UUID
import java.util.stream.Collectors
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import sdu.mdsd.ioT.*

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class IoTGenerator extends AbstractGenerator {
	Device currentDevice;
	List<String> usedSetups;
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		// var model = resource.allContents.filter(Model).toList
		for (dev : resource.allContents.filter(Device).toList) {
			fsa.generateFile('''«dev.name»/«dev.deviceType.fileName»''', dev.convertDevice)
		}
	}
	def convertDevice(Device device) {
		currentDevice = device
		usedSetups = new ArrayList<String>()
		var importString = buildImports(device)
		var programString = buildProgram(device)

		var string =  device.deviceType.body;
		string = string.cleverReplace("{{IMPORTS}}", importString)
		string = string.cleverReplace("{{SETUP}}", buildSetups())
		string = string.cleverReplace("{{PROGRAM}}", programString)
		return string
	}
	def buildImports(Device device) {
		// TODO ideally only import things used in the program, but you know
		var imports = device.deviceType.templates.filter[body.imports !== null].map[body.imports].toList
		var strings = new ArrayList<String>();
		for (import : imports) {
			// Split on new line to get each import as a separate line.
			// So we can check for duplicates
			strings.addAll(import.split("\n"))
		}
		// Return distinct list to string
		return strings.stream.distinct.collect(Collectors.toList()).join("\n")
	}
	def buildSetups() {
		var sb = new StringBuilder();
		for (setup : usedSetups.stream.distinct().collect(Collectors.toList)) {
			sb.append(setup);
			sb.append("\n")
		}
		return sb.toString()
	}
	def buildProgram(Device device) {
		var sb = new StringBuilder()
		var program = device.program
		for (cmd : program.topLevelCommands) {
			sb.append(cmd.generateCode)
			sb.append("\n")
		}
		return sb.toString()
	}

	var loopCount = 0;

	def String generateCode(TopLevelCommand command) {
		var params = new HashMap<String, String>()
		var Class<? extends Template> klass;
		switch (command) {
			WifiStatement: {
				var ssid = command.connectionConfig?.declarations?.extractDeclaration("ssid")?.value;
				var pw = command.connectionConfig?.declarations?.extractDeclaration("password")?.value;
				if (ssid === null || pw === null)
					throw new Exception("You should have a connectConfig before connecting to wifi")
				params.put("ssid", ssid)
				params.put("password", pw)
				klass = WlanTmpl
			}
			ListenStatement: {
				
				params.put("ip", command.ip)
				params.put("port", command.port.toString())
				params.put("commands", command.body.buildCommand)
			klass = SocketListenTmpl
			}
			VarOrList: {
				switch (command) {
					Variable: {
						throw new Exception("NOT IMPLEMENTED YET")
					}
					PyList: {
						params.put("NAME", command.name);
						klass = ListDeclTmpl
					}
					default:
						throw new Exception("NOT A VAR OR LIST")
				}
			}
			Loop: {
				params.put("time", command.convertSleepTime)
				params.put("UUID", loopCount.toString())
				loopCount++;
				params.put("commands", command.command.buildCommands())
				klass = LoopTmpl
			}
			ConnectStatement: {
				throw new Exception("NOT IMPLEMENTED YET")
			}
		}
		doSetup(klass,params)
		return getUseCodeFor(klass, params)
	}

	def String buildCommands(EList<Command> list) {
		var sb = new StringBuilder();
		for (cmd : list) {
			sb.append(cmd.buildCommand())
			sb.append("\n")
		}
		return sb.toString()
	}

	def String buildCommand(Command command) {
		var params = new HashMap<String, String>()
		var Class<? extends Template> klass;
		switch (command) {
			ArrowCommand: {
				params.put("left", command.left.buildCommand)
				params.put("right", command.right.buildCommand)
				val uuid = UUID.randomUUID.toString.replace('-', '_'); // dashes are illegal in method names in python
				params.put("UUID", uuid)
				klass = ArrowTmpl
			}
			ClearListAction: {
				params.put("name", command.list.name)
				klass = ListClearTmpl
			}
			ReadSensor: {
				doSetup(SensorTmpl, params)
				klass = SensorTmpl
			}
			ExternalOf: {
				params.put("method", command.method.name)
				params.put("target", command.target.name)
				klass = ExternalTmpl
			}
			AddToList: {
				params.put("name", command.list.name)
				klass = ListAddTmpl
			}
			SendCommand: {
				params.put("ip", command.target.program.topLevelCommands.filter(ListenStatement).get(0).ip)
				params.put("port",
					command.target.program.topLevelCommands.filter(ListenStatement).get(0).port.toString())
				params.put("target", command.target.name)
				klass = SocketConnectTmpl
			}
			ExternalRight: {
				params.put("method", command.method.name)
				klass = ExternalTmpl
			}
		}
				doSetup(klass,params)
		return getUseCodeFor(klass, params)
	}

	def doSetup(Class<? extends Template> class1, Map<String, String> paramsMap) {

		var templates = currentDevice.deviceType.templates.filter(class1).toList

		for (impl : templates) {
			var setup = impl.body.setup;
			if (setup !== null) {

				var setUpCode = setup.insertParameters(impl.params?.params, paramsMap)
				usedSetups.add(setUpCode);
			}
		}

	}

	def getUseCodeFor(Class<? extends Template> class1, Map<String, String> paramsMap) {
		var sb = new StringBuilder();
		var templates = currentDevice.deviceType.templates.filter(class1).toList

		for (impl : templates) {
			var use = impl.body.use;
			if (use !== null) {

				var useCode = use.insertParameters(impl.params?.params, paramsMap)
				sb.append(useCode)
			}
		}
		return sb.toString()

	}

	def insertParameters(String setup, List<TmplParam> params, Map<String, String> paramsMap) {
		var codeString = setup
		if (codeString === null) {
			throw new Exception("Why is the code string null")
		}
		if (params === null)
			return codeString
		//var paramList = params.replace('(', '').replace(')', '').split(',').map[trim()];
		for (paramObj : params) {
			var param = paramObj.name
			var newValue = paramsMap.get(paramObj.meaning);
			if (newValue === null) {
				throw new Exception('''«param» was null''')
			}
			codeString = codeString.cleverReplace('''{{«param»}}''', newValue)
		}
		return codeString;
	}

	/**
	 * replaces one string with another string and attempts to make nice indentation
	 */
	def cleverReplace(String codeString, String param, String newValue) {
		var codeStringLines = codeString.split("\n")
		var newLines = newValue.split("\n")
		for (var i = 0; i < codeStringLines.length; i++) {
			var line = codeStringLines.get(i);
			if (line.contains(param)) {
				var indentChars = line.toCharArray().takeWhile[c|c == ' ' || c == '\t']
				var resultsb = new StringBuilder()
				for (nline : newLines) {
					resultsb.append(new String(indentChars));
					resultsb.append(line.replace(param, nline))
					resultsb.append('\n')
				}

				codeStringLines.set(i, resultsb.toString())
			}
		}
		return codeStringLines.join('\n')
	}

	def extractDeclaration(List<Declaration> declarations, String _key) {
		val d = declarations.filter[key == _key]
		d.length > 0 ? d.get(0) : null
	}

	def String convertSleepTime(Loop loop) {
		if (loop.timeVal === null) {
			return "0"
		}
		val exp = loop.timeVal

		switch (exp) {
			VarAccess: {
				return exp.variableName.name
			}
			IntExpression: {
				return convertTime(loop.timeUnit, exp.value).toString
			}
			default:
				throw new Exception("Invalid time value" + exp)
		}
	}

	def convertTime(TIMEUNIT timeunit, int timevalue) {
		switch timeunit {
			MILLISECONDS: timevalue / 1000.0
			SECONDS: timevalue
			MINUTES: timevalue * 60
			HOURS: timevalue * 3600
			DAYS: timevalue * 24 * 3600
			WEEKS: timevalue * 7 * 24 * 3600
		}
	}
}
