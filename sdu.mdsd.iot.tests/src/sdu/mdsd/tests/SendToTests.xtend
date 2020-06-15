package sdu.mdsd.tests

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.junit.jupiter.api.^extension.ExtendWith
import sdu.mdsd.ioT.Model
import org.junit.jupiter.api.Test
import sdu.mdsd.ioT.IoTPackage
import sdu.mdsd.validation.IoTValidator

@ExtendWith(InjectionExtension)
@InjectWith(IoTInjectorProvider)
class SendToTests {
	@Inject extension ParseHelper<Model>
	@Inject extension ValidationTestHelper
	
	@Test
	def void abstractTargetTest() {
		'''
			external _ 
			
			abstract a { listen on 192.168.1.5:80 -> _ of value }
			
			controller c {
				var x = 5
					
				always {
					_ of x -> send to a
				} 
			}
		'''.parse.assertError(
			IoTPackage.eINSTANCE.sendCommand, 
			IoTValidator.SENDTO_POINTING_TO_ABSTRACT,
			"Can not send value(s) to abstract device: 'a'"
		)
	}
	
	@Test
	def void targetNotListeningTest() {
		'''
			external _ 
			
			controller a {
				var x = 5
				
				always {
					_ of x -> _ of value
				} 
			}
			
			controller c {
				var x = 5
					
				always {
					_ of x -> send to a
				} 
			}
		'''.parse.assertError(
			IoTPackage.eINSTANCE.sendCommand, 
			IoTValidator.SENDTO_TARGET_NOT_LISTENING,
			"Target device: 'a' not listening for incoming traffic"
		)
	}
	
	@Test
	def void validTargetTest() {
		var r = '''
			external _ 
			
			controller a { 
				listen on 192.168.1.5:80 -> _ of value
			}
			
			controller c {
				var x = 5
					
				always {
					_ of x -> send to a
				} 
			}
		'''.parse
		r.assertNoErrors
	}
	
	@Test
	def void validTargetTest2() {
		var r = '''
			external _ 
			
			abstract a { 
				ip i
				listen on i:80 -> _ of value
			}
			
			controller b : a { ip i = 192.168.1.5 }
			
			controller c {
				var x = 5
					
				always {
					_ of x -> send to b
				} 
			}
		'''.parse
		r.assertNoErrors
	}
}