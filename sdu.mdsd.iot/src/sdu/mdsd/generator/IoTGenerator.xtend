/*
 * generated by Xtext 2.20.0
 */
package sdu.mdsd.generator

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.UUID
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import sdu.mdsd.ioT.AND
import sdu.mdsd.ioT.AbstractDevice
import sdu.mdsd.ioT.AddToList
import sdu.mdsd.ioT.ArrowCommand
import sdu.mdsd.ioT.Block
import sdu.mdsd.ioT.BoolExpression
import sdu.mdsd.ioT.ClearListAction
import sdu.mdsd.ioT.Command
import sdu.mdsd.ioT.Comparison
import sdu.mdsd.ioT.ConnectStatement
import sdu.mdsd.ioT.ControllerDevice
import sdu.mdsd.ioT.DAYS
import sdu.mdsd.ioT.Declaration
import sdu.mdsd.ioT.Device
import sdu.mdsd.ioT.EQL
import sdu.mdsd.ioT.Expression
import sdu.mdsd.ioT.ExpressionLeft
import sdu.mdsd.ioT.ExpressionRight
import sdu.mdsd.ioT.ExternalOf
import sdu.mdsd.ioT.ExternalRight
import sdu.mdsd.ioT.HOURS
import sdu.mdsd.ioT.IfStatement
import sdu.mdsd.ioT.IntExpression
import sdu.mdsd.ioT.IoTDevice
import sdu.mdsd.ioT.ItemBool
import sdu.mdsd.ioT.ItemInt
import sdu.mdsd.ioT.ItemVariable
import sdu.mdsd.ioT.LEDAction
import sdu.mdsd.ioT.LIGHTSENSOR
import sdu.mdsd.ioT.ListenStatement
import sdu.mdsd.ioT.Loop
import sdu.mdsd.ioT.MILLISECONDS
import sdu.mdsd.ioT.MINUTES
import sdu.mdsd.ioT.OR
import sdu.mdsd.ioT.PyList
import sdu.mdsd.ioT.ReadConnection
import sdu.mdsd.ioT.ReadSensor
import sdu.mdsd.ioT.ReadVariable
import sdu.mdsd.ioT.SECONDS
import sdu.mdsd.ioT.SENSOR
import sdu.mdsd.ioT.SendCommand
import sdu.mdsd.ioT.TEMPERATURE
import sdu.mdsd.ioT.TIMEUNIT
import sdu.mdsd.ioT.ToVar
import sdu.mdsd.ioT.True
import sdu.mdsd.ioT.VarAccess
import sdu.mdsd.ioT.VarOrList
import sdu.mdsd.ioT.Variable
import sdu.mdsd.ioT.WEEKS
import sdu.mdsd.ioT.WifiStatement

import static extension sdu.mdsd.utils.FindUtil.findRecursive
import sdu.mdsd.ioT.IpVariable

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class IoTGenerator extends AbstractGenerator {

	Device currentDevice;
	Resource _resource

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		_resource = resource
		
		// find all non abstract devices
		for (dev : resource.allContents.filter(Device).filter(e | !(e instanceof AbstractDevice)).toList) {

			fsa.generateFile('''«dev.name»/main.py''', dev.convDevice)
		}
	}

	/*
	 * Check if LED is used
	 */
	def containsLedAction(Device device) {
		device.findRecursive(LEDAction).size > 0
	}

	/*
	 * Find all external methods used for a given device
	 */
	def getExternals(Device device) {
		var names = device.findRecursive(ExternalOf).map(e|e.method.name).toSet
		names.addAll(device.findRecursive(ExternalRight).map(e|e.method.name).toSet)
		return names
	}

	/*
	 * Generate code for IoT Device
	 */
	def dispatch convDevice(IoTDevice device) {
		currentDevice = device;
		
		// Find and get code for loops
		val loopTexts = new ArrayList<CharSequence>();
		device.findRecursive(Loop).forEach[l, i| loopTexts.add(l.convLoop(i))]
		
		// Find which sensors are used
		var sensorInits = device.findRecursive(SENSOR).convertSensorInitCode

		// Used to detect which device to send commands to
		var sendToCommands = device.findRecursive(SendCommand).toMap([T|T.target.name], [V|V.target.findRecursive(ListenStatement).get(0)])
		
		// Find listen statements
		var listenStatements = device.findRecursive(ListenStatement)
		
		// Find connect statements
		var connectStatements = device.findRecursive(ConnectStatement)
		
		// Check if wifi statement is present
		var wifiStatements = device.findRecursive(WifiStatement)
		
		var string = '''
			import pycom
			import time
			import socket
			import _thread
			from machine import UART,ADC,Pin,idle
			from network import WLAN
			from LTR329ALS01 import LTR329ALS01
			
			«IF (getExternals(device).length > 0)»
				# You need to declare and implement: «FOR moduleName : getExternals(device) SEPARATOR(',')» «moduleName» «ENDFOR»
				import externals
			«ENDIF»
			
			«IF (containsLedAction(device))» 
				pycom.heartbeat(False)
			«ENDIF»
			
			«IF wifiStatements.size > 0»
				« // Only one can exist
				wifiStatements.get(0).convWifiStatement»
			«ENDIF»
			
			«FOR connectionStatement : connectStatements»
				«connectionStatement.convConfigurationIoT»	
				
			«ENDFOR»
			
			«FOR target : sendToCommands.keySet»
				socket«target» = socket.socket()
				socket«target».setblocking(True)
				socket«target».connect(('«sendToCommands.get(target).ip»', «sendToCommands.get(target).port»))
			«ENDFOR»
			
			«FOR v : device.extractVariables»
				«v.convToPy»
			«ENDFOR»
			
			«sensorInits»
			
			«FOR t : loopTexts»
				«t»
			«ENDFOR»
			
			«insertSocketCode(listenStatements)»
		'''
		currentDevice = null;
		return string
	}
	
	/*
	 * Recursivly extracts lists, variables and ip variables
	 */
	def extractVariables(Device device) {
		var vl = new ArrayList<VarOrList>
		vl.addAll(device.findRecursive(PyList))
		val varNames = newArrayList
		vl.addAll(device.findRecursive(Variable)
				.filter[v | v.value !== null]
				.filter[v | 
					if (varNames.contains(v.name)) {
						false
					} else {
						varNames.add(v.name)
						true
					}
				]
				.toList)
		val ipNames = newArrayList
		vl.addAll(device.findRecursive(IpVariable)
				.filter[v | v.value !== null]
				.filter[v | 
					if (ipNames.contains(v.name)) {
						false
					} else {
						ipNames.add(v.name)
						true
					}
				]
				.toList)
		// Reversed to get inherited variables first 
		vl.reverse
	}
	

	def CharSequence convertSensorInitCode(List<SENSOR> s) {
		var string = ""
		if (!s.filter(LIGHTSENSOR).isEmpty) {
			string += '''
				integration_time = LTR329ALS01.ALS_INT_50
				measurement_rate = LTR329ALS01.ALS_RATE_50 
				gain = LTR329ALS01.ALS_GAIN_1X 
				lightsensor = LTR329ALS01(integration=integration_time, rate=measurement_rate, gain=gain)
			'''
		}
		if (!s.filter(TEMPERATURE).isEmpty) {
			string += '''
				p_out = Pin('P19', mode=Pin.OUT)
				p_out.value(1)
				adc = ADC()             # create an ADC object
				apin = adc.channel(pin='P16', attn=2)   # create an analog pin on P16
			'''
		}
		string
	}

	def convToPy(VarOrList vl) {
		switch vl {
			Variable: '''«vl.name»  = «vl.value.convVariableValue»'''
			PyList: '''«vl.name» = []'''
			IpVariable: '''«vl.name» = "«vl.value»"'''
			default: throw new Exception("VarOrList type not supported")
		}
	}

	def String convVariableValue(Expression exp) {
		switch exp {
			BoolExpression: exp.value instanceof True ? "True" : "False"
			IntExpression: exp.value + ""
			VarAccess: exp.variableName.name
			default: throw new Exception("Variable type not supported")
		}
	}

	def CharSequence convLoop(Loop loop, int i) {
		'''
			def th_func«i»(action):
				while True:
					time.sleep(«loop.convertSleepTime»)
					action()
					
			def loop«i»():
				«FOR cmd : loop.command»
					«cmd.convCMD()»
				«ENDFOR»
			
			_thread.start_new_thread(th_func«i», (loop«i»,))
			
		'''
	}

	def String convertSleepTime(Loop loop) {
		if (loop.timeVal === null) {
			return "0"
		}
		val exp = loop.timeVal

		return switch (exp) {
			VarAccess: exp.variableName.name
			IntExpression: convertTime(loop.timeUnit, exp.value).toString
			default: throw new Exception("Invalid time value" + exp)
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

	def CharSequence convCMD(Command cmd) {

		switch cmd {
			ClearListAction: '''
				global «cmd.list.name»
				«cmd.list.name» = []
			'''
			LEDAction: '''pycom.rgbled(«cmd.state == 'ON' ? '0xFFFFFF':'0x000000'»)'''
			ArrowCommand: {
				val uuid = UUID.randomUUID.toString.replace('-', '_'); // dashes are illegal in method names in python
				'''
					def expLeft«uuid»():
						«cmd.left.convExpLeft»
					
					
					def expRight«uuid»(value):
						«cmd.right.convExpRight»
					
					
					result = expLeft«uuid»()
					expRight«uuid»(result)
				'''
			}
			IfStatement: '''
					if («cmd.condition.convComparison»):
						«FOR content : cmd.commands»
						«content.convCMD»
						«ENDFOR»
					«IF (cmd.elseBlock !== null)»
					else:
						«FOR line : cmd.elseBlock.commands»
						«line.convCMD»
						«ENDFOR»
					«ENDIF»
				'''
		}
	}

	def CharSequence convComparison(Comparison comp) {
		switch comp {
			AND: '''«comp.left.convComparison» and «comp.right.convComparison»'''
			EQL: '''«comp.left.convComparison» «comp.op.op» «comp.right.convComparison»'''
			ItemBool: '''«comp.value»'''
			ItemInt: '''«comp.value»'''
			ItemVariable: '''«comp.value.name»'''
			OR: '''«comp.left.convComparison» or «comp.right.convComparison»'''
		}

	}

	def convExpRight(ExpressionRight right) {
		switch (right) {
			SendCommand: right.target.sendToDevice
			AddToList: '''«right.list.name».append(value)'''
			ToVar: '''
				global «right.variable.name»
				«right.variable.name» = value
				'''
			ExternalRight: '''externals.«right.method.name»(value)'''
			Block: '''«FOR cmd : right.commands » «cmd.convCMD» «ENDFOR»'''
			default: throw new Exception(right.class.toString + " not implemented for ExpressionRight")
		}
	}

	def getSendToDevice(Device targetDevice) {
		var connectionList = this.currentDevice.program.connectStatements.filter([device == targetDevice]).toList
		var connection = connectionList.length > 0
				? connectionList.get(0)
				: targetDevice.eAllContents.filter(ListenStatement).toList.get(0)

		return switch (connection) {
			ConnectStatement: currentDevice.serialWrite(targetDevice) // Send over serial
			ListenStatement: '''socket«targetDevice.name».send(bytes(str(value), "utf8"))''' // Send over wifi
			default: throw new Exception("No connection config found. Requires either 1 serial or 1 listen statement")
		}
	}

	def dispatch serialWrite(IoTDevice device, Device _) {
		return '''print(value)''' // print sends a value over serial USB connection on PyCom devices.
	}

	def dispatch serialWrite(ControllerDevice device, Device targetDevice) {
		return '''serial«targetDevice.name».write(bytes(str(value) + "\n", "utf8"))'''
	}

	def convExpLeft(ExpressionLeft left) {
		switch (left) {
			ReadVariable: '''return «left.value.name»'''
			ReadSensor: left.sensor.getReadSensorCode
			ReadConnection: left.source.readFromDevice
			ExternalOf: '''return externals.«left.method.name»(«left.target.name»)'''
			BoolExpression: '''return «left.convVariableValue»'''
			IntExpression: '''return «left.convVariableValue»'''
		}
	}

	def CharSequence readFromDevice(Device sourceDevice) {
		var connectionList = this.currentDevice.program.connectStatements.filter([device == sourceDevice]).toList
		var connection = connectionList.length > 0 ? connectionList.get(0) : throw new Exception("A connection to the device not found")
		val type = connection.configuration.type
		switch (currentDevice) {
			IoTDevice case type == "WLAN": '''return socket.recv(1024)'''
			IoTDevice case type == "SERIAL": '''return uart.readline()'''
			ControllerDevice case type == "WLAN": '''return socket.recv(1024)'''
			ControllerDevice case type == "SERIAL": '''return serial«sourceDevice.name».readline()'''
			default: throw new Exception("Connect config not found")
		}
	}

	def getGetReadSensorCode(SENSOR sensor) {
		switch (sensor) {
			LIGHTSENSOR: '''
				luxTuple = lightsensor.light()
				lux = (luxTuple[0]+luxTuple[1])/2
				return lux
			'''
			TEMPERATURE: '''
				temperature = apin()
				return temperature
			'''
		}
	}

	def dispatch convDevice(ControllerDevice device) {
		currentDevice = device;
		
		// Find and get code for loops
		val loopTexts = new ArrayList<CharSequence>();
		device.findRecursive(Loop).forEach[l, i| loopTexts.add(l.convLoop(i))]
		
		var listenStatements = device.findRecursive(ListenStatement)
		
		// Used to detect which device to send commands to
		var sendToCommands = device.findRecursive(SendCommand).toMap([T|T.target.name], [V|V.target.findRecursive(ListenStatement).get(0)])
		
		var string = '''
			import serial
			import time
			import socket
			import select
			import _thread
			
			# Initializer
			
			«IF (getExternals(device).length > 0)»
				# You need to declare and implement: «FOR moduleName : getExternals(device) SEPARATOR(',')» «moduleName» «ENDFOR»
				import externals
			«ENDIF»
			
			«FOR connectionStatement : device.program.connectStatements»
				«connectionStatement.convConfigurationController»
			«ENDFOR»
			
			«FOR target : sendToCommands.keySet»
				socket«target» = socket.socket()
				socket«target».setblocking(True)
				socket«target».connect(('«sendToCommands.get(target).ip»', «sendToCommands.get(target).port»))
			«ENDFOR»
			
			«FOR v : device.extractVariables»
				«v.convToPy»
			«ENDFOR»
			
			«FOR t : loopTexts»
				«t»
			«ENDFOR»
			
			«insertSocketCode(listenStatements)»
			
			# Do nothing forever, because the thread(s) started above would exit if this (main) thread exits.
			while True:
				time.sleep(100)
		'''
		currentDevice = null;
		return string
	}
	
	def String insertSocketCode(List<ListenStatement> listenStatements) {
		if (listenStatements.length < 1) return ""
		
		var ls = listenStatements.get(0)
		
		'''
		server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		print('Socket created')				
		
		# Bind socket to local host and port
		try:
			server.bind(('«ls.ip»', «ls.port»))
		except socket.error as msg:
		    print('Bind failed. Error Code : ' + msg + ' Message ' + str(msg))
		    sys.exit()
		
		server.listen(10)
		input = [server, ]  # a list of all connections we want to check for data
		# each time we call select.select()
		
		def run_server():
		    inputready, outputready, exceptready = select.select(input, [], [])
		
		    for s in inputready:  # check each socket that select() said has available data
		
		        if s == server:  # if select returns our server socket, there is a new
		                        # remote socket trying to connect
		            client, address = server.accept()
		            # add it to the socket list so we can check it now
		            input.append(client)
		            print('new client added%s' % str(address))
		
		        else:
		            # select has indicated that these sockets have data available to recv
		            data = s.recv(1024)
		            if data:
		                value = str(data) # read data
		                value = value[2:-1] # remove b'...'
		                
		                «ls.body.convExpRight»
		                 
		def th_func_socket(action):
			while True:
				action()
		
		_thread.start_new_thread(th_func_socket, (run_server,))
		'''
	}

	def String convWifiStatement(WifiStatement statement) {
		val map = getWlanIotValues(statement.connectionConfig.declarations)
		'''
			SSID = '«map.get('ssid')»'
			KEY = '«map.get('password')»'
			
			wlan = WLAN(mode=WLAN.STA)
			nets = wlan.scan()
			for net in nets:
				if net.ssid == SSID:
					print('Network found!')
					wlan.connect(net.ssid, auth=(net.sec, KEY), timeout=5000)
					while not wlan.isconnected():
						idle() # save power while waiting
					print('WLAN connection succeeded!')
					print(wlan.ifconfig()) # Print the connection settings, IP, Subnet mask, Gateway, DNS
					break
		'''
	}

	def String convConfigurationIoT(ConnectStatement statement) {
		var configuration = statement.configuration
		switch configuration.type {
			case 'SERIAL': {
				var map = getSerialIotValues(configuration.declarations)
				'''
					uart = UART(«statement.address.value»)
					uart.init(«map.get('baudrate')», bits=«map.get('bits')», parity=«map.get('parity')», stop=«map.get('stopbit')»)
				'''
			}
			default: throw new Exception(statement.class.toString + " unexpected for method convConfigurationIoT.")
		}
	}

	def String convConfigurationController(ConnectStatement statement) {
		var map = getSerialControllerValues(statement.configuration.declarations)
		return switch statement.configuration.type {
			case 'SERIAL': 	'''
							serial«statement.device.name»= serial.Serial(
							    port='«statement.address.value»',
							    baudrate=«map.get('baudrate')»,
							    parity=«map.get('parity')»,
							    stopbits=«map.get('stopbit')»,
							    bytesize=«map.get('bytesize')»
							)
							'''
			default: throw new Exception("Connect statement not supported")//"" 
		}
	}

	def extractDeclaration(List<Declaration> declarations, String _key) {
		val d = declarations.filter[key == _key]
		d.length > 0 ? d.get(0) : null
	}

	def getSerialControllerValues(List<Declaration> declarations) {
		val baudrate = declarations.extractDeclaration('baudrate')?.value
		val stopbit = declarations.extractDeclaration('stopbit')?.value
		val bytesize = declarations.extractDeclaration('bytesize')?.value
		val parity = declarations.extractDeclaration('parity')?.value
		val convertedParity = parity.convertParityToPy

		var map = new HashMap<String, String>()
		// Serial
		map.put('baudrate', baudrate ?: '115200')
		map.put('stopbit', stopbit ?: '1')
		map.put('bytesize', bytesize ?: '8')
		map.put('parity', convertedParity ?: 'serial.PARITY_NONE')
		map
	}

	def String convertParityToPy(String parity) {
		switch (parity) {
			case '0',
			case 'None': 'serial.PARITY_NONE'
			case 'even': "serial.PARITY_EVEN"
			case "odd": "serial.PARITY_ODD"
			case "mark": "serial.PARITY_MARK"
			case "space": "serial.PARITY_SPACE"
			default: null
		}
	}

	def getSerialIotValues(List<Declaration> declarations) {
		val baudrate = declarations.extractDeclaration('baudrate')?.value
		val stopbit = declarations.extractDeclaration('stopbit')?.value
		val bits = declarations.extractDeclaration('bits')?.value
		val parity = declarations.extractDeclaration('parity')?.value
		val bus = declarations.extractDeclaration('bus')?.value

		var map = new HashMap<String, String>()
		// Serial
		map.put('baudrate', baudrate ?: '115200')
		map.put('stopbit', stopbit ?: '1')
		map.put('bits', bits ?: '8')
		map.put('parity', parity ?: 'None')
		map
	}

	def getWlanIotValues(List<Declaration> declarations) {
		val ssid = declarations.extractDeclaration('ssid')?.value
		val password = declarations.extractDeclaration('password')?.value

		var map = new HashMap<String, String>()
		// Serial
		map.put('ssid', ssid ?: 'INPUT SSID')
		map.put('password', password ?: 'INPUT PASSWORD')
		map
	}

}