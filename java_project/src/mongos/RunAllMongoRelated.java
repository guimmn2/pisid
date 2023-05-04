package mongos;
import java.awt.*;
import javax.swing.*;

public class RunAllMongoRelated {
    public static void main(String[] args) {
        CloudToMongo ctm = CloudToMongo.getInstance();
        Backup bck = Backup.getInstance();
        
        // create the main JFrame
        JFrame frame = new JFrame();
        frame.setTitle("Mongo Tools");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        
        // create a new JPanel to hold the CloudToMongo frame
        JPanel ctmPanel = new JPanel(new BorderLayout());
        ctmPanel.add(ctm.getContentPane(), BorderLayout.CENTER);
        
        // create a new JPanel to hold the Backup frame
        JPanel bckPanel = new JPanel(new BorderLayout());
        bckPanel.add(bck.getContentPane(), BorderLayout.CENTER);
        
        // create two JPanels to hold the existing windows
        JPanel leftPanel = new JPanel(new BorderLayout());
        leftPanel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 10)); // add margins
        leftPanel.add(ctmPanel, BorderLayout.CENTER); // add CloudToMongo panel to left panel
        
        JPanel rightPanel = new JPanel(new BorderLayout());
        rightPanel.setBorder(BorderFactory.createEmptyBorder(20, 10, 20, 20)); // add margins
        rightPanel.add(bckPanel, BorderLayout.CENTER); // add Backup panel to right panel
        

        // create an empty panel for the gap
        JPanel gapPanel = new JPanel();
        gapPanel.setPreferredSize(new Dimension(15, 560)); // set the preferred width and height
        gapPanel.setBackground(Color.WHITE); // set the background color
        
        ctmPanel.setPreferredSize(new Dimension(700, 560));
        bckPanel.setPreferredSize(new Dimension(700, 560));
        
        // add the JPanels to the main JFrame
        frame.setLayout(new BorderLayout());
        frame.add(leftPanel, BorderLayout.WEST);
        frame.add(gapPanel, BorderLayout.CENTER);
        frame.add(rightPanel, BorderLayout.EAST);
        
        frame.pack();
        
        // show the main JFrame
        frame.setVisible(true);
    }
}
