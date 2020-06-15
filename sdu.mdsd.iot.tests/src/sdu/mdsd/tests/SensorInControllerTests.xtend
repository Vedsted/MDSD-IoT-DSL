package sdu.mdsd.tests
import com.google.inject.Inject
import org.eclipse.emf.ecore.EClass
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith
import sdu.mdsd.ioT.IoTPackage
import sdu.mdsd.ioT.Model
import sdu.mdsd.validation.IoTValidator

@ExtendWith(InjectionExtension)
@InjectWith(IoTInjectorProvider)
class SensorInControllerTests {
	@Inject extension ParseHelper<Model>
	@Inject extension ValidationTestHelper
	
	@Test
	def void sensorInController() {
		'''
			controller test {
				var y = 0
				
				every 1 SECONDS {
					read from LIGHTSENSOR -> to x 
				}
			}
		'''.parse.assertSensor('test')
	}
	
	private def assertSensor(Model m, String name) {
		m.assertError(
			IoTPackage.eINSTANCE.controllerDevice, 
			IoTValidator.SENSOR_IN_CONTROLLER,
			"Sensor used in Controller device: '" + name + "'"
		)
	}
	
	@Test
	def void sensorInheritedInController() {
		'''
			abstract abs {
				var x = 0
				
				every 1 SECONDS {
					read from LIGHTSENSOR -> to x 
				}
			}
			
			controller test : abs {
				var y = 0
				
				every 1 SECONDS {
					read var y -> to y 
				}
			}
		'''.parse.assertInheritedSensor('test', 'abs')
	}
	
	@Test
	def void sensorInheritedInController2() {
		'''
			abstract abs1 {
				var x = 0
				
				every 1 SECONDS {
					read from LIGHTSENSOR -> to x 
				}
			}
			
			abstract abs2 : abs1 {}
			
			controller test : abs2 {
				var y = 0
				
				every 1 SECONDS {
					read var y -> to y 
				}
			}
		'''.parse.assertInheritedSensor('test', 'abs2')
	}
	
	private def assertInheritedSensor(Model m, String cName, String aName) {
		m.assertError(
			IoTPackage.eINSTANCE.controllerDevice, 
			IoTValidator.SENSOR_INHERITED_IN_CONTROLLER,
			"Sensor inherited in Controller device: '" + cName + "' from Abstract device: '" + aName + "'"
		)
	}
	
	@Test
	def void testValidController() {
		'''			
			controller test {
				var y = 0
				
				every 1 SECONDS {
					read var y -> to y 
				}
			}
		'''.parse.assertNoErrors
	}
	
	@Test
	def void testValidControllerInheritance() {
		'''
			abstract abs1 {
				var x = 0
				
				every 1 SECONDS {
					read var x -> to x 
				}
			}
			
			abstract abs2 : abs1 {}
			
			controller test : abs2 {
				var y = 0
				
				every 1 SECONDS {
					read var y -> to y 
				}
			}
		'''.parse.assertNoErrors
	}
}